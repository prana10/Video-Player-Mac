class Config {
  static String urlVideo = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8";

  static String formatDuration(Duration? duration) {
    if (duration == null) {
      return '0:00';
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '$minutes:${twoDigits(seconds)}';
    }
  }
}
