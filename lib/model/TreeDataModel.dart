class TreeDataModel {
  final String speciesName;
  final double totalHeight;
  final double x;
  final double y;
  final String fileName;

  TreeDataModel({
    required this.speciesName,
    required this.totalHeight,
    required this.x,
    required this.y,
    required this.fileName,
  });

  Map<String, dynamic> toMap() {
    return {
      'speciesName': speciesName,
      'totalHeight': totalHeight,
      'x': x,
      'y': y,
      'fileName': fileName,
    };
  }
}
