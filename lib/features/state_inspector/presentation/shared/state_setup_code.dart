/// The code an app adds so State Inspector › Controls can send a snapshot
/// back into it, by handshake `platform`: the file it goes in and the code.
const stateRestoreSetup = {
  'react_native': (
    'App.tsx',
    'DevConnect.onStateRestore((state) =>\n'
        '  store.dispatch({\n'
        '    type: "RESTORE_STATE",\n'
        '    payload: state,\n'
        '  }),\n'
        ');\n'
        '// root reducer\n'
        'const rootReducer = (state, action) =>\n'
        '  action.type === "RESTORE_STATE"\n'
        '    ? action.payload\n'
        '    : appReducer(state, action);',
  ),
  'flutter': (
    'main.dart',
    '// after await DevConnect.init(...)\n'
        'DevConnect.onStateRestore =\n'
        '    (state) => store.restore(state);',
  ),
  'android': (
    'Application.kt',
    '// runs on the main thread\n'
        'DevConnect.onStateRestore = { state ->\n'
        '    viewModel.restore(state)\n'
        '}',
  ),
};

/// The code an app adds so State Inspector › Controls can dispatch actions
/// into it, by handshake `platform`.
const stateDispatchSetup = {
  'react_native': ('App.tsx', 'DevConnect.connectReduxStore(store);'),
  'flutter': (
    'main.dart',
    '// after await DevConnect.init(...)\n'
        'DevConnect.onReduxDispatch =\n'
        '    (action) => store.dispatch(action);',
  ),
  'android': (
    'Application.kt',
    '// runs on the main thread\n'
        'DevConnect.onReduxDispatch = { action ->\n'
        '    viewModel.handle(action)\n'
        '}',
  ),
};

/// [platform]'s restore and dispatch code as one block, a comment they
/// share written once.
String stateControlsSetup(String platform) {
  final restore = stateRestoreSetup[platform]!.$2;
  final dispatch = stateDispatchSetup[platform]!.$2.split('\n');
  final shared =
      dispatch.first.startsWith('//') && restore.startsWith(dispatch.first);
  return '$restore\n\n${(shared ? dispatch.skip(1) : dispatch).join('\n')}';
}

/// A handshake `platform` as people say it.
String platformName(String platform) => switch (platform) {
  'react_native' => 'React Native',
  'flutter' => 'Flutter',
  'android' => 'Android',
  _ => platform,
};
