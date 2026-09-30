# Autoria do piloto de escadas — contrato mínimo v1

Origem local=(0,0), origem baseline=(2050,4000). Apenas translação. Escala1 unidade por pixel, sem resize não uniforme. Footprint físico1200x360, subida oeste[0,0,200,360], patamar[200,0,800,360], subida leste[1000,0,200,360]. Altura física contínua44; Oeste sobe para+x, Leste para-x. Y visual = Y físico-altura.

Produzir arquivos novos em art/scenarios/scn-production/farol-docas-v01/stairs/ e metadados próprios. Base não escreverá nesse diretório. Aceitos AtlasTexture/PNG transparentes, preservando fonte/autoria. Texturas de degrau/piso nativas, face frontal44 e orientações explicitamente autoradas. Não usar imagens rejeitadas nem comprimir face68 para44.

A composição pode usar o kit existente e as16 faixas25x360 do JSON de proposta. Alturas visuais0,6,11,17,22,28,33,39, patamar44. Base medirá discrepância máxima frente à rampa física contínua (<6 unidades), não a tratará como aprovação de pés. Orientações não autoradas rejeitadas.

Entrega mínima: manifest.json com schema_version=1, height=44, world_units_per_pixel=1, allowed_transforms=[translate], textures com face44, floor, west_tread/east_tread quando distintos (res paths), source/source_rect/dimensions/provenance. Face44 pode ser autoria procedural determinística com paleta do kit e variações simples de juntas, se aspecto for inspecionado. Não gerar tudo de novo quando composição resolve.

Base fará drawables ground/top/face e ordenação por pés projetados, simulação/colisão existentes, culling e comparação de duas origens. Não duplicar decoração incorporada. Nenhuma arte nova entra na run normal antes da validação de bancada. Corredores W/E/N preservados.
