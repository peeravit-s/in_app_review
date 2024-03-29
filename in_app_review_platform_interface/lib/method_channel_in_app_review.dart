import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:platform/platform.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'in_app_review_platform_interface.dart';

/// An implementation of [InAppReviewPlatform] that uses method channels.
class MethodChannelInAppReview extends InAppReviewPlatform {
  MethodChannel _channel = MethodChannel('dev.britannio.in_app_review');
  Platform _platform = const LocalPlatform();

  @visibleForTesting
  set channel(MethodChannel channel) => _channel = channel;

  @visibleForTesting
  set platform(Platform platform) => _platform = platform;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    return _channel
        .invokeMethod<bool>('isAvailable')
        .then((available) => available ?? false, onError: (_) => false);
  }

  @override
  Future<void> requestReview() => _channel.invokeMethod('requestReview');

  @override
  Future<HuaweiReview> requestHuaweiReview() async {
    try {
      bool result = await _channel.invokeMethod('requestHuaweiReview');
      return HuaweiReview('success', '-1', result);
    } on PlatformException catch (e) {
      // Throw a specific exception for Huawei review errors
      return HuaweiReview('Failed to request Huawei in-app review: $e', e.code, false);
    } on MissingPluginException catch (e) {
      return HuaweiReview('Failed to request Huawei in-app review: $e', '888', false);
    } catch (e) {
      return HuaweiReview('Failed to request Huawei in-app review: $e', '999', false);
    }
  }

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {
    final bool isiOS = _platform.isIOS;
    final bool isMacOS = _platform.isMacOS;
    final bool isAndroid = _platform.isAndroid;
    final bool isWindows = _platform.isWindows;

    if (isiOS || isMacOS) {
      await _channel.invokeMethod(
        'openStoreListing',
        ArgumentError.checkNotNull(appStoreId, 'appStoreId'),
      );
    } else if (isAndroid) {
      await _channel.invokeMethod('openStoreListing');
    } else if (isWindows) {
      ArgumentError.checkNotNull(microsoftStoreId, 'microsoftStoreId');
      await _launchUrl(
        'ms-windows-store://review/?ProductId=$microsoftStoreId',
      );
    } else {
      throw UnsupportedError(
        'Platform(${_platform.operatingSystem}) not supported',
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await canLaunchUrlString(url)) return;
    await launchUrlString(url, mode: LaunchMode.externalNonBrowserApplication);
  }
}

class HuaweiReview {
  final String message;
  final String code;
  final bool success;

  HuaweiReview(this.message, this.code, this.success);
}
