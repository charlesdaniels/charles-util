# -*- mode: python -*-

block_cipher = None


a = Analysis(['nios2-search.py'],
             pathex=['/home/cad/src/git/charles-util/src/nios2-tools'],
             binaries=[],
             datas=[],
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='nios2-search',
          debug=False,
          strip=True,
          upx=True,
          runtime_tmpdir=None,
          console=True )
