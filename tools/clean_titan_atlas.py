"""Gera o atlas do Titan com uma margem segura entre os quadros.

O atlas criado por IA ocupa as bordas de várias células. Ao amostrar o quadro,
isso pode trazer fragmentos da pose vizinha para dentro do jogo. Este utilitário
recorta a borda contaminada, redimensiona com nearest-neighbour e cria um gutter
transparente em cada célula.
"""

from pathlib import Path
from collections import deque

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "mech" / "titan_v3.png"
OUTPUT = ROOT / "assets" / "mech" / "titan_v3_clean.png"
CELL = 176
COLS = 10
ROWS = 5
INSET_X = 10
INSET_TOP = 6
INSET_BOTTOM = 8
GUTTER = 6


def isolate_main_sprite(frame: Image.Image) -> Image.Image:
    """Remove fragmentos desconectados que pertencem aos quadros vizinhos."""
    alpha = frame.getchannel("A")
    width, height = frame.size
    solid = bytearray(1 if value > 12 else 0 for value in alpha.getdata())
    visited = bytearray(width * height)
    components: list[list[int]] = []
    for start in range(width * height):
        if not solid[start] or visited[start]:
            continue
        queue = deque([start])
        visited[start] = 1
        component: list[int] = []
        while queue:
            index = queue.popleft()
            component.append(index)
            x, y = index % width, index // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < width and 0 <= ny < height:
                    neighbour = ny * width + nx
                    if solid[neighbour] and not visited[neighbour]:
                        visited[neighbour] = 1
                        queue.append(neighbour)
        components.append(component)

    if not components:
        return frame
    main = max(components, key=len)
    keep = bytearray(width * height)
    for index in main:
        keep[index] = 255
    # Expande a máscara para conservar o antialiasing ao redor do corpo principal.
    for _ in range(2):
        expanded = keep[:]
        for index, value in enumerate(keep):
            if not value:
                continue
            x, y = index % width, index // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < width and 0 <= ny < height:
                    expanded[ny * width + nx] = 255
        keep = expanded
    clean_alpha = Image.new("L", frame.size)
    original_alpha = list(alpha.getdata())
    clean_alpha.putdata([value if keep[index] else 0 for index, value in enumerate(original_alpha)])
    cleaned = frame.copy()
    cleaned.putalpha(clean_alpha)
    return cleaned


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    expected = (CELL * COLS, CELL * ROWS)
    if source.size != expected:
        raise ValueError(f"atlas inesperado: {source.size}, esperado {expected}")

    output = Image.new("RGBA", expected, (0, 0, 0, 0))
    target_size = (CELL - GUTTER * 2, CELL - GUTTER * 2)
    for row in range(ROWS):
        for col in range(COLS):
            left = col * CELL
            top = row * CELL
            frame = source.crop(
                (
                    left + INSET_X,
                    top + INSET_TOP,
                    left + CELL - INSET_X,
                    top + CELL - INSET_BOTTOM,
                )
            )
            frame = isolate_main_sprite(frame)
            frame.thumbnail(target_size, Image.Resampling.LANCZOS)
            x = left + (CELL - frame.width) // 2
            y = top + CELL - GUTTER - frame.height
            output.alpha_composite(frame, (x, y))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    output.save(OUTPUT, optimize=True)
    print(f"Atlas limpo salvo em {OUTPUT}")
    # 0.15: linhas 3 e 4 viram costas de verdade (sem viseira/núcleo)
    from titan_back_view import main as apply_back_view
    apply_back_view()


if __name__ == "__main__":
    main()
