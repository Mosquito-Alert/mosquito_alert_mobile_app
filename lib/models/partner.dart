class Partner {
  int id;
  var point;
  String textualDescription;
  String pageUrl;

  Partner({
    this.id,
    this.point,
    this.textualDescription,
    this.pageUrl,
  });

  Partner.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    point = json['point'];
    textualDescription = json['textual_description'];
    pageUrl = json['page_url'];
  }
}
