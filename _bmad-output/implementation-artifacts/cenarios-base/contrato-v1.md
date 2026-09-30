# SCN-01.04 — contrato v1 para adaptação

API executável: scripts/scenarios/room_contract.gd. Testes: tests/scenarios_base/room_contract_test.gd. Publicado em 30/09/2026 para adaptação isolada; ainda não habilita geração na run normal.

RoomTemplate é Dictionary local em unidades do jogo. Campos: template_id, version=1, era_id, biome_id, room_role, allowed_transforms=[translate], footprint:Array[Rect2], connectors:Array[{id,position:Vector2,normal:Vector2 cardinal,width,height,type}], layers:Array[{id,rect:Rect2,texture:res path,mode:tile|plate,depth:ground|foreground,material?:floor}], obstacles:Array[{rect,kind,baked,layer_id?}], spawns:Array[{id,position,radius}], points_of_interest:Array[{id,position}], gaps/raised:Array[Rect2], ramps:Array[{rect,axis,low,high}].

instantiate(template,instance_id,origin,transform_id=translate) valida antes de devolver. Falha: {ok:false,errors:Array[String]}. Sucesso: cópia materializada com ok:true, instance_id, origin, transform_id; todas coordenadas deslocadas igualmente. Espelho/rotação não suportados. Não é promessa de gerador completo.

contains(instance,point) identifica sala incluindo alas; clear_at(instance,point,radius) usa união do footprint e obstáculos/gaps; visible_obstacles exclui baked sem retirar colisão. Portas devem cobrir borda externa do footprint; spawn não pode ficar em parede. Geometria global/conectividade/altura entre salas são responsabilidade SCN-04.

Seed: scripts/scenarios/seed_manifest.gd derive(seed,biome,floor,room,version), SHA256 da tupla canônica, primeiros60 bits, subfluxo map. Seeds de64 bits serializadas como strings. canonical(value) ordena chaves; chamador ordena arrays de IDs. select lê sim.seed_value (adaptador legado; RunDirector ausente).

Envelope do grafo da frente Procedural pode conservar seu schema prototype-only e adicionar adapter explícito para estes templates. IDs de nodes tornam-se instance_id; profile→biome_id explícito; edges devem conter endpoints e connector IDs após seleção. Não inventar portas/locks como já validados. Catalog fingerprint deve cobrir conteúdo, versões e elegibilidade. Fallback permanece diagnóstico até ter catálogo aprovado.

Catálogo de bancada: scripts/scenarios/biomes.json. Docas baseline_only; rail_test test_only. Nenhuma era publicada. Renderer de prévia room_preview.gd usa dados; bancada --contract --profile=rail_test. Shared runtime permanece intocado pela base.
