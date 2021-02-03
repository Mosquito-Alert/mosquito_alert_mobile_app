class Campaign {
  int id;
  String postingAddress;
  String startDate;
  String endDate;

  Campaign({
    this.id,
    this.postingAddress,
    this.startDate,
    this.endDate,
  });

  Campaign.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    postingAddress = json['posting_address'];
    startDate = json['campaign_start_date'];
    endDate = json['campaign_end_date'];
  }
}
