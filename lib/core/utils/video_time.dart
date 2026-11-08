/// Formats a video position as total minutes and seconds (mm:ss).
String formatVideoTime(Duration value) =>
    '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
