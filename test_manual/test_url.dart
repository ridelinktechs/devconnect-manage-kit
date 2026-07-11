import 'package:devconnect_manage_tool/core/utils/network_url_formatter.dart';

void main() {
  final url = 'https://ennfhoxhnhsdsxnpkwvd.supabase.co/rest/v1/legal_documents?select=id%2Cdocument_key%2Cdocument_type%2Caudience%2Clanguage%2Cversion%2Ceyebrow%2Ctitle%2Csubtitle%2Csummary_heading%2Csummary_body%2Cconfirm_label%2Cconfirm_sublabel%2Ccta_label%2Ceffective_date%2Csections%2Cnotice_text%2Cnotice_link_text%2Cnotice_link_target%2Cis_active&audience=eq.customer&language=eq.vi&is_active=eq.true&order=document_type.asc';
  print('=== formatUrlPretty ===');
  print(formatUrlPretty(url));
  print('=== formatUrlCompact ===');
  print(formatUrlCompact(url));
  print('=== formatUrlOneLine ===');
  print(formatUrlOneLine(url));
}
