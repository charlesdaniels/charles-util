# -*- mode: python -*-

block_cipher = None


a = Analysis(['abs2rel.py'],
             pathex=['/home/cad/src/git/charles-util/src/abs2rel'],
             binaries=[],
             datas=[],
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          [],
          name='abs2rel',
          debug=False,
          bootloader_ignore_signals=False,
          strip=True,
          upx=True,
          runtime_tmpdir=None,
          console=True )
