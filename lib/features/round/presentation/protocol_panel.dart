import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'protocol/graphql/graphql_tab.dart';
import 'protocol/grpc/grpc_tab.dart';
import 'protocol/protocol_tabs.dart';
import 'protocol/websocket/websocket_tab.dart';

/// Round 3 — Protocol inspector (GraphQL + WebSocket + gRPC).
///
/// Implemented as a single tabbed panel with 3 sub-tabs at the top so a
/// QA can pivot between protocols without leaving the Network Inspector.
class ProtocolPanel extends ConsumerStatefulWidget {
  const ProtocolPanel({super.key});

  @override
  ConsumerState<ProtocolPanel> createState() => _ProtocolPanelState();
}

class _ProtocolPanelState extends ConsumerState<ProtocolPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProtocolTabs(controller: _tab),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              GraphqlTab(),
              WebsocketTab(),
              GrpcTab(),
            ],
          ),
        ),
      ],
    );
  }
}
