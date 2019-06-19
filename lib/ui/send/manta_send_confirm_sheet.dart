import 'dart:async';

import 'package:event_taxi/event_taxi.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manta_dart/manta_wallet.dart' as mwallet;
import 'package:manta_dart/messages.dart' as mmsg;

import 'package:natrium_wallet_flutter/appstate_container.dart';
import 'package:natrium_wallet_flutter/dimens.dart';
import 'package:natrium_wallet_flutter/styles.dart';
import 'package:natrium_wallet_flutter/localization.dart';
import 'package:natrium_wallet_flutter/service_locator.dart';
import 'package:natrium_wallet_flutter/bus/events.dart';
import 'package:natrium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:natrium_wallet_flutter/ui/widgets/dialog.dart';
import 'package:natrium_wallet_flutter/ui/widgets/sheets.dart';
import 'package:natrium_wallet_flutter/ui/util/ui_util.dart';
import 'package:natrium_wallet_flutter/util/numberutil.dart';
import 'package:natrium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:natrium_wallet_flutter/util/biometrics.dart';
import 'package:natrium_wallet_flutter/util/hapticutil.dart';
import 'package:natrium_wallet_flutter/util/caseconverter.dart';
import 'package:natrium_wallet_flutter/model/authentication_method.dart';
import 'package:natrium_wallet_flutter/model/vault.dart';
import 'package:natrium_wallet_flutter/ui/widgets/security.dart';

final Logger log = new Logger("Manta");

bool isManta(String candidate) {
  return mwallet.MantaWallet.parseUrl(candidate) != null;
}

class MantaSendConfirmSheet {
  mwallet.MantaWallet _manta;

  bool animationOpen = false;

  MantaSendConfirmSheet(String url) {
    _manta = mwallet.MantaWallet(url);
  }

  Future  _authenticate(BuildContext context, String description) async {
    // Authenticate the user by using either fingerprint or pin
    final i18n = AppLocalization.of(context);
    final authKind = await sl.get<SharedPrefsUtil>().getAuthMethod();
    final hasBio = await sl.get<BiometricUtil>().hasBiometrics();
    log.info("in authenticate");
    if (authKind.method == AuthMethod.BIOMETRICS && hasBio) {
      // fingerprint
      if (await sl.get<BiometricUtil>()
        .authenticateWithBiometrics(context, i18n.sendAmountConfirm)) {
        sl.get<HapticUtil>().fingerprintSucess();
        return context;
      };

    } else {
      // pin
      final pin = await sl.get<Vault>().getPin();
      final nextCtx = await Navigator.of(context).push(
        MaterialPageRoute(
          maintainState: false,
          builder:
          (BuildContext context) {
            return new PinScreen(
              PinOverlayType.ENTER_PIN,
              (pin) {
                Navigator.of(context).pop(context);
              },
              expectedPin: pin, description: description);
      }));
      return nextCtx;
    }
  }

  void _authenticateAndSend(BuildContext context, mmsg.PaymentRequestMessage payReq) async {
    // authenticate the user and perform the payment by asking the server to do
    // the nano transaction and then by send the final message to the manta
    // processor with the payment details.
    context = await _authenticate(context, payReq.merchant.name);
    if (context == null) return;
    await _startLoadAnimation(context);
    final sc = StateContainer.of(context);
    final dest = payReq.destinations[0];
    bool sent = false;
    var  processResponse;
    processResponse = EventTaxiImpl.singleton().registerTo<ProcessEvent>().listen(
      (event) {
        processResponse.cancel();
        if (!sent) _manta.sendPayment(
          transactionHash: event.response.hash,
          cryptoCurrency: "NANO");
        sent = true;
    });
    sc.requestSend(sc.wallet.frontier, dest.destination_address,
      NumberUtil.getAmountAsRaw(mmsg.decimal_to_str(dest.amount)));
  }

  Widget _confirmDialog(BuildContext context, mmsg.PaymentRequestMessage payReq) {
    // The confirm dialog showed just before the final authentication and
    // sending. It contains details informations about the recipient.
    final merchant = payReq.merchant;
    final destination = payReq.destinations[0];
    return Column(
      children: <Widget>[
        // Sheet handle
        Container(
          margin: EdgeInsets.only(top: 10),
          height: 5,
          width: MediaQuery.of(context).size.width * 0.15,
          decoration: BoxDecoration(
            color: StateContainer.of(context).curTheme.text10,
            borderRadius: BorderRadius.circular(100.0),
          ),
        ),
        //The main widget that holds the text fields, "SENDING" and "TO" texts
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // "SENDING" TEXT
              Container(
                margin: EdgeInsets.only(bottom: 10.0),
                child: Column(
                  children: <Widget>[
                    Text(
                      CaseChange.toUpperCase(
                        AppLocalization.of(context).sending,
                        context),
                      style: AppStyles.textStyleHeader(context),
                    ),
                  ],
                ),
              ),
              // Container for the amount text
              Container(
                margin: EdgeInsets.only(
                  left:
                  MediaQuery.of(context).size.width * 0.105,
                  right: MediaQuery.of(context).size.width *
                  0.105),
                padding: EdgeInsets.symmetric(
                  horizontal: 25, vertical: 15),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: StateContainer.of(context)
                  .curTheme
                  .backgroundDarkest,
                  borderRadius: BorderRadius.circular(50),
                ),
                // Amount text
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: '',
                    children: [
                      TextSpan(
                        text: "${mmsg.decimal_to_str(destination.amount)}",
                        style: TextStyle(
                          color: StateContainer.of(context)
                          .curTheme
                          .primary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NunitoSans',
                        ),
                      ),
                      TextSpan(
                        text: " NANO",
                        style: TextStyle(
                          color: StateContainer.of(context)
                          .curTheme
                          .primary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w100,
                          fontFamily: 'NunitoSans',
                        ),
                      ),
                      TextSpan(
                        text: " (${mmsg.decimal_to_str(payReq.amount)} ${payReq.fiat_currency})",
                        style: TextStyle(
                          color: StateContainer.of(context)
                          .curTheme
                          .primary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NunitoSans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // "TO" text
              Container(
                margin: EdgeInsets.only(top: 30.0, bottom: 10),
                child: Column(
                  children: <Widget>[
                    Text(
                      CaseChange.toUpperCase(
                        AppLocalization.of(context).to,
                        context),
                      style: AppStyles.textStyleHeader(context),
                    ),
                  ],
                ),
              ),
              // Address text
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 25.0, vertical: 15.0),
                margin: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width *
                  0.105,
                  right: MediaQuery.of(context).size.width *
                  0.105),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: StateContainer.of(context)
                  .curTheme
                  .backgroundDarkest,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: UIUtil.threeLineAddressText(
                  context, destination.destination_address,
                  contactName: merchant.name + ", " + merchant.address)),
            ],
          ),
        ),

        //A container for CONFIRM and CANCEL buttons
        Container(
          child: Column(
            children: <Widget>[
              // A row for CONFIRM Button
              Row(
                children: <Widget>[
                  // CONFIRM Button
                  AppButton.buildAppButton(
                    context,
                    AppButtonType.PRIMARY,
                    CaseChange.toUpperCase(
                      AppLocalization.of(context).confirm,
                      context),
                    Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                      _authenticateAndSend(context, payReq);
                    }
                  ),
                ],
              ),
              // A row for CANCEL Button
              Row(
                children: <Widget>[
                  // CANCEL Button
                  AppButton.buildAppButton(
                    context,
                    AppButtonType.PRIMARY_OUTLINE,
                    CaseChange.toUpperCase(
                      AppLocalization.of(context).cancel,
                      context),
                    Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                      Navigator.of(context).pop();
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<mmsg.PaymentRequestMessage> _getPaymentDetails() async {
    await _manta.connect();
    final mmsg.PaymentRequestEnvelope payReqEnv = await _manta.getPaymentRequest(
      cryptoCurrency: "NANO");
    final mmsg.PaymentRequestMessage payReq = payReqEnv.unpack();
    log.info("Data: ${payReq.toJson()}");
    return payReq;
  }

  StatefulBuilder _modal(Widget child, {WillPopCallback onWillPop = null}) {
    // Show a widget as modal
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return WillPopScope(onWillPop: onWillPop, child: child);
    });
  }

  Widget _safe(BuildContext context, Widget child) {
    return SafeArea(
      minimum: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.035),
      child: child);
  }

  Future<void> _startLoadAnimation(BuildContext context) async {
    final theme = StateContainer.of(context).curTheme;
    animationOpen = true;
    final loader = AnimationLoadingOverlay(AnimationType.SEND,
      theme.animationOverlayStrong, theme.animationOverlayMedium,
      onPoppedCallback: () => animationOpen = false);
    Navigator.of(context).push(loader);
    await loader.didPush();
  }

  mainBottomSheet(BuildContext context) async {
    final nav = Navigator.of(context);
    await _startLoadAnimation(context);
    try {
      log.info("Trying to connect to the server");
      final payReq = await _getPaymentDetails().timeout(Duration(seconds: 10));
      nav.pop();
      AppSheets.showAppHeightNineSheet(
        context: context,
        builder: (BuildContext context) {
          return _modal(_safe(context, _confirmDialog(context, payReq)));
        }
      );
    } catch (e) {
      log.info("Connection failure");
      nav.pop();
      UIUtil.showSnackbar(AppLocalization.of(context).sendError, context);
    }
  }
}
