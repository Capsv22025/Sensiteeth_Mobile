class AnalysisResult {
  final String imageUrl;
  final String result;

  AnalysisResult({required this.imageUrl, required this.result});

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'result': result,
    };
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      imageUrl: json['imageUrl'],
      result: json['result'],
    );
  }
}
