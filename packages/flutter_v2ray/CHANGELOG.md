## 1.0.10

* update xray core version to 25.3.6

## 1.0.9

* add disconnect button (notificationDisconnectButtonName)
* fix requestPermission
* fix notification bugs  (android 13 and higher)

## 1.0.8

* fix registerReceiver error
* fix build for API 34 ( check IntentFilter V2RAY_CONNECTION_INFO )
* change type of usage statistic
* fix deprecated apis
* update v2ray core to 1.8.17

## 1.0.7

* fix v2rayBroadCastReceiver null exception
* fix #35: registerReceiver error
* update libv2ray to 1.8.7
* fix #43: Adding DNS servers to the VPN service

## 1.0.6

* fix #24 issue: fix notification and background service
* fix #11 issue: add bypassSubnets for bypass lan traffic
* add getConnectedServerDelay
* add getCoreVersion
* optimize java codes

## 1.0.5

* fix #10 issue: notification service

## 1.0.4

* fix getServerDelay

## 1.0.3

* fix vless fingerprint 
* update android XRay version

## 1.0.2

* fix #4 issue: tlsSettings -> path
* fix #7 issue: reset total traffic after disconnect 
* validate json config

## 1.0.1

* fix EventChannel crash
* add getServerDelay method

## 1.0.0

* implement v2ray for android
* create v2ray share link parser
