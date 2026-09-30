
## Inspeção visual executada

Farol baseline mostra rampas/face e decoração existentes. Capela inteira e duas alas cabem no enquadramento com três portas marcadas. Capturas de1280x800 e1920x1080 da régua foram inspecionadas: Marty/Titan/Guardião usam sprites reais sem escala compensatória. Sonda occlusion--10 confirma perda completa da silhueta atrás do pilar; a marca de pés permite localizar a oclusão. É achado do ambiente atual, não aprovação de jogabilidade. Treze resoluções foram renderizadas; somente as amostras indicadas foram inspecionadas manualmente nesta revisão.

Perfil rail_test revelou chão desenhado fora da ala e overlays herdados; corrigidos clipping por footprint e geometria do overlay a partir da instância. Recaptura final desse perfil ainda necessária após o merge concorrente. Nenhum playtest humano, coop físico ou desempenho foi declarado.
