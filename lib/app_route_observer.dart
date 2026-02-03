import 'package:flutter/material.dart';

/// 用于在从子页面 pop 回壳层时通知社群页等刷新
final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();
