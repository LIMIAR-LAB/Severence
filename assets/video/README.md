# Abertura

`opening.ogv` é a introdução aprovada com transições suaves (`art/video/severence-intro-60s-v2.mp4`), convertida para Theora/Vorbis em 1920×1080 para reprodução nativa no Godot.

A cena inicial é `scenes/intro.tscn`. Ao terminar, pressionar uma tecla, um botão do controle ou clicar em PULAR, abre `scenes/main.tscn`. O vídeo respeita o volume salvo e mantém proporção 16:9. O menu não fica rodando por baixo da abertura.

Para ferramentas e testes, `-- --skip-intro` abre diretamente o menu. Capturas e testes de rede também ignoram a abertura.

Teste: Godot `--headless --path . --script tests/intro_test.gd -- --full-intro` verifica inclusive o término real dos 60 segundos.
