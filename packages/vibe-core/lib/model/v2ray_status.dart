class V2RayStatus {
  final String duration;
  final int uploadSpeed;
  final int downloadSpeed;
  final int upload;
  final int download;
  final String state;

  V2RayStatus({
    this.duration = "00:00:00",
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.upload = 0,
    this.download = 0,
    this.state = "DISCONNECTED",
  });
}
