import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  static Future<void> openGoogleMaps() async {
    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/place/Changlun+Tour%2FChanglun+CNT+Enterprise/@6.4247874,100.2843377,12z/data=!4m10!1m2!2m1!1scnt+enterprise!3m6!1s0x304ca583351a6b3b:0xf622162dfc1a2005!8m2!3d6.4247874!4d100.4285333!15sCg5jbnQgZW50ZXJwcmlzZVoQIg5jbnQgZW50ZXJwcmlzZZIBC3RvdXJfYWdlbmN5mgEkQ2hkRFNVaE5NRzluUzBWSlEwRm5TVVI0TTNGbE4yOUJSUkFC4AEA-gEECAAQNA!16s%2Fg%2F11f_92f5tx?entry=ttu&g_ep=EgoyMDI2MDMyNC4wIKXMDSoASAFQAw%3D%3D",
    );

    try {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print("Could not open Google Maps: $e");
    }
  }

  static Future<void> openNavigation() async {
    final Uri navigationUrl = Uri.parse(
      "google.navigation:q=13.7563,100.5018",
    );

    final Uri fallbackUrl = Uri.parse(
      "https://www.google.com/maps/place/Changlun+Tour%2FChanglun+CNT+Enterprise/@6.4247874,100.4285333,17z/data=!3m1!4b1!4m6!3m5!1s0x304ca583351a6b3b:0xf622162dfc1a2005!8m2!3d6.4247874!4d100.4285333!16s%2Fg%2F11f_92f5tx?authuser=0&hl=en&entry=ttu&g_ep=EgoyMDI2MDMyNC4wIKXMDSoASAFQAw%3D%3D",
    );

    try {
      if (await canLaunchUrl(navigationUrl)) {
        await launchUrl(
          navigationUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await launchUrl(
          fallbackUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print("Could not open navigation: $e");
    }
  }
}