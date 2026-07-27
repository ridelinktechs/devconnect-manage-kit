/// Static install-command templates for the AI clients we support.
///
/// Add a new client by appending an enum value + a const entry to [mcpClients].
enum McpClientId { claudeCode, codex, cursor }

class TokenCommandTemplate {
  final McpClientId clientId;
  final String displayName;
  final String binaryName;

  /// Command shown when the user picks the `npx` install mode. Stdio
  /// transport — the AI client spawns `npx -y devconnect-manage` as a
  /// child process.
  final String command;

  /// Command shown when the user picks the `localhost` install mode.
  /// HTTP transport — the AI client connects to a local MCP server
  /// already running on the desktop's machine. See [localhostCommandAt].
  final String localhostCommand;
  final String uninstallCommand;
  final String downloadUrl;

  const TokenCommandTemplate({
    required this.clientId,
    required this.displayName,
    required this.binaryName,
    required this.command,
    required this.localhostCommand,
    required this.uninstallCommand,
    required this.downloadUrl,
  });
}

/// Default port the local HTTP MCP server listens on. Chosen to avoid
/// colliding with the desktop WebSocket control channel (5564).
const int defaultLocalMcpHttpPort = 5565;

/// Build the localhost-mode install command for a given AI client +
/// port. Cursor is special — it has no CLI, the user clicks "Run
/// install" and we write `~/.cursor/mcp.json` directly.
String localhostCommandAt(McpClientId client, int port) {
  final url = 'http://127.0.0.1:$port/mcp';
  switch (client) {
    case McpClientId.claudeCode:
      return 'claude mcp add --transport http devconnect-manage $url --scope user';
    case McpClientId.codex:
      return 'codex mcp add devconnect-manage --url $url';
    case McpClientId.cursor:
      return 'Click "Run install" to automatically configure ~/.cursor/mcp.json ($url)';
  }
}

final Map<McpClientId, TokenCommandTemplate> mcpClients = {
  McpClientId.claudeCode: TokenCommandTemplate(
    clientId: McpClientId.claudeCode,
    displayName: 'Claude Code',
    binaryName: 'claude',
    command:
        'claude mcp add -s user --transport stdio devconnect-manage -- npx -y devconnect-manage',
    localhostCommand:
        'claude mcp add --transport http devconnect-manage http://127.0.0.1:$defaultLocalMcpHttpPort/mcp --scope user',
    uninstallCommand: 'claude mcp remove -s user devconnect-manage',
    downloadUrl: 'https://claude.com/download',
  ),
  McpClientId.codex: TokenCommandTemplate(
    clientId: McpClientId.codex,
    displayName: 'Codex',
    binaryName: 'codex',
    command: 'codex mcp add devconnect-manage -- npx -y devconnect-manage',
    localhostCommand:
        'codex mcp add devconnect-manage --url http://127.0.0.1:$defaultLocalMcpHttpPort/mcp',
    uninstallCommand: 'codex mcp remove devconnect-manage',
    downloadUrl: 'https://github.com/openai/codex',
  ),
  McpClientId.cursor: TokenCommandTemplate(
    clientId: McpClientId.cursor,
    displayName: 'Cursor',
    binaryName: 'cursor',
    command: 'Click "Run install" to automatically configure ~/.cursor/mcp.json',
    localhostCommand:
        'Click "Run install" to automatically configure ~/.cursor/mcp.json (http://127.0.0.1:$defaultLocalMcpHttpPort/mcp)',
    uninstallCommand: 'Click "Uninstall" to automatically remove the configuration',
    downloadUrl: 'https://cursor.com',
  ),
};