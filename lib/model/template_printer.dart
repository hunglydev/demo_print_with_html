class TemplatePrinter {
  int? id;
  String? name;
  String? content;
  bool? status;
  String? tenantCode;

  TemplatePrinter(
      {this.id, this.name, this.content, this.status, this.tenantCode});

  TemplatePrinter.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    content = json['content'];
    status = json['status'];
    tenantCode = json['tenant_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['content'] = content;
    data['status'] = status;
    data['tenant_code'] = tenantCode;
    return data;
  }
}
