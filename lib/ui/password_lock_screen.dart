import 'package:flutter/material.dart';
import 'package:natrium_wallet_flutter/app_icons.dart';
import 'package:natrium_wallet_flutter/service_locator.dart';
import 'package:natrium_wallet_flutter/model/authentication_method.dart';
import 'package:natrium_wallet_flutter/model/vault.dart';
import 'package:natrium_wallet_flutter/styles.dart';
import 'package:natrium_wallet_flutter/util/biometrics.dart';
import 'package:natrium_wallet_flutter/util/nanoutil.dart';
import 'package:natrium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:natrium_wallet_flutter/util/caseconverter.dart';
import 'package:natrium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:natrium_wallet_flutter/ui/widgets/security.dart';
import 'package:natrium_wallet_flutter/appstate_container.dart';
import 'package:natrium_wallet_flutter/localization.dart';
import 'package:natrium_wallet_flutter/dimens.dart';
import 'package:natrium_wallet_flutter/ui/util/routes.dart';

class AppPasswordLockScreen extends StatefulWidget {
  @override
  _AppPasswordLockScreenState createState() => _AppPasswordLockScreenState();
}

class _AppPasswordLockScreenState extends State<AppPasswordLockScreen> {
  FocusNode enterPasswordFocusNode;
  TextEditingController enterPasswordController;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        color: StateContainer.of(context).curTheme.backgroundDark,
        width: double.infinity,
        child: SafeArea(
          minimum: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.035,
            top: MediaQuery.of(context).size.height * 0.1,
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Column(
                children: <Widget>[
                  Container(
                    child: Icon(
                      AppIcons.lock,
                      size: 80,
                      color: StateContainer.of(context).curTheme.primary,
                    ),
                    margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.1),
                  ),
                  Container(
                    child: Text(
                      CaseChange.toUpperCase(
                          AppLocalization.of(context).locked, context),
                      style: AppStyles.textStyleHeaderColored(context),
                    ),
                    margin: EdgeInsets.only(top: 10),
                  ),
                  // Enter your password Text Field
                  Container(
                    margin: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.105,
                      right: MediaQuery.of(context).size.width * 0.105,
                      top: 30,
                    ),
                    padding: EdgeInsetsDirectional.only(start: 16, end: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          StateContainer.of(context).curTheme.backgroundDarkest,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Material(
                        color: Colors.transparent,
                        child: TextField(
                          focusNode: enterPasswordFocusNode,
                          controller: enterPasswordController,
                          cursorColor:
                              StateContainer.of(context).curTheme.primary,
                          textInputAction: TextInputAction.go,
                          // Temporary function
                          onSubmitted: (String text) {
                            Navigator.of(context).pop();
                          },
                          // Temporary function END
                          maxLines: 1,
                          autocorrect: false,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText:
                                AppLocalization.of(context).enterPasswordHint,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w100,
                              fontFamily: 'NunitoSans',
                              color: StateContainer.of(context).curTheme.text60,
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.0,
                            color: StateContainer.of(context).curTheme.primary,
                            fontFamily: 'NunitoSans',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )),
              Row(
                children: <Widget>[
                  AppButton.buildAppButton(
                      context,
                      AppButtonType.PRIMARY,
                      AppLocalization.of(context).unlock,
                      Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                    // Temporary function
                    Navigator.of(context).pop();
                    //Temporary function end
                  }),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
