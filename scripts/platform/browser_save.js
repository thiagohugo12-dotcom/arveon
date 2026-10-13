// Origin-local journal. Godot's IndexedDB remains the filesystem; this small
// synchronous mirror protects writes made immediately before page termination.
(function (root) {
  'use strict';
  const KEY = 'grande-arvore-rpg.save.v6';
  const PREVIOUS = KEY + '.previous';
  const MAX = 262144;
  function create(storage) {
    let expected = null;
    let readable = false;
    return {
      read() {
        try { expected = storage.getItem(KEY); readable = true; return expected || ''; }
        catch (_) { readable = false; return ''; }
      },
      available() { return readable; },
      write(text, replace = false) {
        if (typeof text !== 'string' || text.length > MAX) return 'invalid';
        try {
          const current = storage.getItem(KEY);
          if (!replace && current !== expected) return 'conflict';
          if (current === text) return 'ok';
          if (current !== null) {
            // Immutable historical source, separate from rotating recovery mirror.
            let outer;
            try { outer = JSON.parse(current); } catch (_) { outer = {}; }
            const payload = typeof outer.payload === 'string' ? JSON.parse(outer.payload) : outer;
            if (Number.isInteger(payload.version) && payload.version > 0 && payload.version < 10) {
              const original = KEY + '.v' + payload.version + '.original';
              if (storage.getItem(original) === null) storage.setItem(original, current);
              if (storage.getItem(original) === null) return 'storage';
            }
            storage.setItem(PREVIOUS, current);
          }
          storage.setItem(KEY, text);
          if (storage.getItem(KEY) !== text) return 'storage';
          expected = text;
          readable = true;
          return 'ok';
        } catch (_) { return 'storage'; }
      },
      onHidden(callback) {
        const hidden = () => { if (root.document.visibilityState === 'hidden') callback(); };
        root.document.addEventListener('visibilitychange', hidden);
        root.addEventListener('pagehide', callback);
        return () => {
          root.document.removeEventListener('visibilitychange', hidden);
          root.removeEventListener('pagehide', callback);
        };
      },
      pick(callback) {
        const input = root.document.createElement('input');
        input.type = 'file'; input.accept = '.json,application/json';
        input.style.display = 'none'; root.document.body.appendChild(input);
        input.onchange = async () => {
          try {
            const file = input.files[0];
            if (file) callback(file.size > MAX ? '' : await file.text());
          } catch (_) { callback(''); }
          finally { input.remove(); }
        };
        input.oncancel = () => input.remove();
        input.click();
      }
    };
  }
  if (typeof module !== 'undefined') module.exports = { create, KEY, PREVIOUS };
  else {
    let storage;
    try { storage = root.localStorage; } catch (_) { storage = {getItem(){throw Error();}}; }
    root.GrandeArvoreSave = create(storage);
  }
})(typeof window === 'undefined' ? globalThis : window);
