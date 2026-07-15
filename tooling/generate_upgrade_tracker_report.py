from reportlab.lib.colors import Color, HexColor, white
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from reportlab.platypus import Paragraph
from reportlab.pdfgen.canvas import Canvas


OUT = "output/pdf/upgrade-tracker-implementation-report.pdf"
W, H = A4
NAVY = HexColor("#111827")
INK = HexColor("#172033")
MUTED = HexColor("#667085")
SURFACE = HexColor("#F4F6FA")
LINE = HexColor("#D8DEE9")
RED = HexColor("#E0302B")
GOLD = HexColor("#F2B84B")
BLUE = HexColor("#4A90E2")
PURPLE = HexColor("#8B5CF6")
GREEN = HexColor("#2FA36B")
ORANGE = HexColor("#E78A35")


def font_setup():
    regular = "/System/Library/Fonts/SFNS.ttf"
    bold = "/System/Library/Fonts/SFNSRounded.ttf"
    try:
        pdfmetrics.registerFont(TTFont("App", regular))
        pdfmetrics.registerFont(TTFont("AppBold", bold))
    except Exception:
        pass


def title(c, kicker, heading, sub=None):
    c.setFillColor(RED)
    c.setFont("AppBold", 8)
    c.drawString(18 * mm, H - 18 * mm, kicker.upper())
    c.setFillColor(INK)
    c.setFont("AppBold", 25)
    c.drawString(18 * mm, H - 31 * mm, heading)
    if sub:
        c.setFillColor(MUTED)
        c.setFont("App", 9.5)
        c.drawString(18 * mm, H - 39 * mm, sub)


def footer(c, page):
    c.setStrokeColor(LINE)
    c.line(18 * mm, 13 * mm, W - 18 * mm, 13 * mm)
    c.setFillColor(MUTED)
    c.setFont("App", 7)
    c.drawString(18 * mm, 8 * mm, "ClashKing Upgrade Tracker · implementation report · July 2026")
    c.drawRightString(W - 18 * mm, 8 * mm, str(page))


def card(c, x, y, w, h, fill=white, radius=5 * mm, stroke=LINE):
    c.setFillColor(fill)
    c.setStrokeColor(stroke)
    c.roundRect(x, y, w, h, radius, fill=1, stroke=1)


def p(c, text, x, y, w, size=9, color=INK, bold=False, leading=None, align=None):
    style = ParagraphStyle(
        "p",
        fontName="AppBold" if bold else "App",
        fontSize=size,
        leading=leading or size * 1.35,
        textColor=color,
        alignment=align or 0,
    )
    para = Paragraph(text, style)
    _, h = para.wrap(w, 200 * mm)
    para.drawOn(c, x, y - h)
    return h


def pill(c, x, y, text, fill=SURFACE, color=INK):
    c.setFont("AppBold", 7)
    width = c.stringWidth(text, "AppBold", 7) + 8 * mm
    c.setFillColor(fill)
    c.roundRect(x, y, width, 7 * mm, 3.5 * mm, fill=1, stroke=0)
    c.setFillColor(color)
    c.drawCentredString(x + width / 2, y + 2.25 * mm, text)
    return width


def page_one(c):
    c.setFillColor(NAVY)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(RED)
    c.roundRect(18 * mm, H - 31 * mm, 31 * mm, 9 * mm, 4.5 * mm, fill=1, stroke=0)
    c.setFillColor(white)
    c.setFont("AppBold", 8)
    c.drawCentredString(33.5 * mm, H - 27.7 * mm, "IMPLEMENTED")
    c.setFont("AppBold", 30)
    p(c, "Upgrade Tracker", 18 * mm, H - 59 * mm, 170 * mm, 30, white, True, 34)
    p(c, "Performance + visual system refresh", 18 * mm, H - 79 * mm, 170 * mm, 18, HexColor("#CAD2E1"), True)
    p(c, "A faster, calmer tracker with shared DevKit primitives, import-first onboarding, visible data freshness, and plan-derived village completion dates.", 18 * mm, H - 101 * mm, 168 * mm, 12, HexColor("#AEB9CB"), False, 17)
    y = 57 * mm
    labels = [("6", "performance changes"), ("7", "tracker design primitives"), ("5", "village cost/time sections")]
    for i, (num, label) in enumerate(labels):
        x = 18 * mm + i * 58 * mm
        c.setFillColor(Color(1, 1, 1, alpha=0.06))
        c.roundRect(x, y, 51 * mm, 28 * mm, 5 * mm, fill=1, stroke=0)
        c.setFillColor(white)
        c.setFont("AppBold", 20)
        c.drawString(x + 6 * mm, y + 12 * mm, num)
        p(c, label, x + 18 * mm, y + 20 * mm, 28 * mm, 8, HexColor("#CAD2E1"), True)
    c.setFillColor(HexColor("#6D778A"))
    c.setFont("App", 8)
    c.drawString(18 * mm, 18 * mm, "ClashKingApp + DevKit · validated implementation")


def page_two(c):
    title(c, "Performance", "Six changes aimed at scroll smoothness", "Work is now paid only when the visible UI needs it.")
    changes = [
        ("1", "Virtualized grids", "Wrap + shrinkWrap eagerly built every upgrade and collection tile. SliverGrid.builder now creates visible cells on demand."),
        ("2", "Local search state", "Search, sort, and filters moved into their tabs, so typing no longer rebuilds the entire tracker shell and every page."),
        ("3", "Cached derived data", "Item filters, summaries, static lookups, and collection indexes are memoized instead of rescanned during routine rebuilds."),
        ("4", "Scoped ticking", "A ValueNotifier updates only active timers and the freshness label; the root page no longer setStates every second."),
        ("5", "Cheaper image/audio work", "Owned art avoids ColorFiltered, scenery audio uses disk loading, and its position timer stops whenever playback stops."),
        ("6", "Deferred secondary work", "Imported snapshots are parsed once, reused from cache, and widget synchronization waits for the first frame at idle priority."),
    ]
    y = H - 54 * mm
    for i, (num, heading, body) in enumerate(changes):
        col = i % 2
        row = i // 2
        x = 18 * mm + col * 89 * mm
        yy = y - row * 60 * mm
        card(c, x, yy - 48 * mm, 82 * mm, 49 * mm)
        c.setFillColor(RED if i < 2 else BLUE if i < 4 else GREEN)
        c.circle(x + 9 * mm, yy - 9 * mm, 5 * mm, fill=1, stroke=0)
        c.setFillColor(white)
        c.setFont("AppBold", 8)
        c.drawCentredString(x + 9 * mm, yy - 11.5 * mm, num)
        p(c, heading, x + 18 * mm, yy - 5 * mm, 58 * mm, 10, INK, True)
        p(c, body, x + 7 * mm, yy - 20 * mm, 68 * mm, 8.2, MUTED, False, 11)
    footer(c, 2)


def page_three(c):
    title(c, "DevKit", "A semantic style sheet for tracker UI", "Roles are named by purpose, so screens stop inventing weights, colors, and density.")
    card(c, 18 * mm, 158 * mm, 174 * mm, 81 * mm, SURFACE)
    p(c, "TYPE ROLES", 25 * mm, 229 * mm, 60 * mm, 8, RED, True)
    roles = [("Hero metric", "32 / 800"), ("Screen title", "24 / 700"), ("Section title", "17 / 700"), ("Row title", "15 / 600"), ("Body", "15 / 500"), ("Metadata", "12 / 500")]
    for i, (role, spec) in enumerate(roles):
        yy = 217 * mm - i * 9 * mm
        c.setFillColor(INK)
        c.setFont("AppBold" if i < 3 else "App", 12 if i == 0 else 9)
        c.drawString(25 * mm, yy, role)
        c.setFillColor(MUTED)
        c.setFont("App", 8)
        c.drawRightString(92 * mm, yy, spec)
    p(c, "Dynamic Type is inherited from Flutter TextTheme. Compact controls keep a 44pt minimum and grow when text scales.", 106 * mm, 225 * mm, 76 * mm, 9, MUTED, False, 13)
    yy = 197 * mm
    pill(c, 106 * mm, yy, "Compact · 44pt", white)
    pill(c, 147 * mm, yy, "Standard · 52pt", white)
    p(c, "STATE COLORS", 18 * mm, 145 * mm, 60 * mm, 8, RED, True)
    colors = [("Builders", GOLD), ("Research", BLUE), ("Pets", PURPLE), ("Complete", GREEN), ("Scheduled", ORANGE), ("Unavailable", HexColor("#98A2B3"))]
    for i, (label, color) in enumerate(colors):
        x = 18 * mm + (i % 3) * 59 * mm
        y = 119 * mm - (i // 3) * 25 * mm
        card(c, x, y, 52 * mm, 18 * mm)
        c.setFillColor(color)
        c.roundRect(x + 5 * mm, y + 5 * mm, 8 * mm, 8 * mm, 2 * mm, fill=1, stroke=0)
        c.setFillColor(INK)
        c.setFont("AppBold", 8)
        c.drawString(x + 17 * mm, y + 7.5 * mm, label)
    p(c, "MATERIAL RULE", 18 * mm, 73 * mm, 60 * mm, 8, RED, True)
    card(c, 18 * mm, 34 * mm, 82 * mm, 31 * mm, Color(0.93, 0.96, 1, alpha=1), stroke=BLUE)
    p(c, "Glass for focus", 25 * mm, 57 * mm, 66 * mm, 10, INK, True)
    p(c, "Hero and floating controls only.", 25 * mm, 48 * mm, 66 * mm, 8, MUTED)
    card(c, 110 * mm, 34 * mm, 82 * mm, 31 * mm, white)
    p(c, "Quiet sections", 117 * mm, 57 * mm, 66 * mm, 10, INK, True)
    p(c, "Lists use low-contrast CKSectionPanel.", 117 * mm, 48 * mm, 66 * mm, 8, MUTED)
    footer(c, 3)


def phone(c, x, y, w, h):
    c.setFillColor(NAVY)
    c.roundRect(x, y, w, h, 10 * mm, fill=1, stroke=0)
    c.setFillColor(white)
    c.roundRect(x + 2 * mm, y + 2 * mm, w - 4 * mm, h - 4 * mm, 8 * mm, fill=1, stroke=0)
    c.setFillColor(NAVY)
    c.roundRect(x + w / 2 - 12 * mm, y + h - 6 * mm, 24 * mm, 3 * mm, 1.5 * mm, fill=1, stroke=0)


def page_four(c):
    title(c, "Village summary", "Completion dates and costs, by queue", "Plan math powers finish dates; walls and equipment stay explicitly untimed.")
    phone(c, 20 * mm, 29 * mm, 78 * mm, 206 * mm)
    x, top = 27 * mm, 220 * mm
    p(c, "Home Village", x, top, 62 * mm, 15, INK, True)
    p(c, "83.4% complete · 146 levels left", x, top - 10 * mm, 62 * mm, 7.5, MUTED)
    sections = [
        ("Builder artwork", "Builders · 6", "Completes Nov 18 · 129d", GOLD, "45.2M Gold"),
        ("Lab artwork", "Laboratory", "Completes Feb 4 · 207d", BLUE, "71.8M Elixir"),
        ("Pet artwork", "Pets", "Completes Aug 29 · 48d", PURPLE, "18.6M Dark Elixir"),
        ("Wall artwork", "Walls", "312 levels remaining", HexColor("#98A2B3"), "1.42B Gold / Elixir"),
        ("Gear artwork", "Equipment", "38 levels remaining", ORANGE, "84.3K Ore"),
    ]
    yy = top - 24 * mm
    for asset, heading, meta, color, cost in sections:
        card(c, x, yy - 29 * mm, 64 * mm, 27 * mm, SURFACE, 3 * mm, SURFACE)
        c.setFillColor(color)
        c.roundRect(x + 4 * mm, yy - 23 * mm, 14 * mm, 17 * mm, 3 * mm, fill=1, stroke=0)
        c.setFillColor(white)
        c.setFont("App", 5.5)
        c.drawCentredString(x + 11 * mm, yy - 15 * mm, asset.split()[0])
        p(c, heading, x + 21 * mm, yy - 6 * mm, 38 * mm, 8.5, INK, True)
        p(c, meta, x + 21 * mm, yy - 15 * mm, 38 * mm, 6.5, MUTED)
        p(c, cost, x + 21 * mm, yy - 22 * mm, 38 * mm, 6.5, color, True)
        yy -= 32 * mm
    p(c, "ACCOUNTING RULES", 111 * mm, 217 * mm, 74 * mm, 8, RED, True)
    rules = [
        ("Builder finish", "Uses the same plan lanes as Plan, including the actual builder count for Home Village or Builder Base."),
        ("Lab + pets", "Each queue has its own completion date, duration, and resource totals; pets appear only for Home Village."),
        ("Walls + equipment", "Shown as explicit cost sections with no fabricated date because their upgrades have no time."),
        ("Builders + helpers", "Visible under their villages, but excluded from Home Village and Builder Base overall completion."),
        ("Game artwork", "Every row selects the relevant Clash asset; no generic category glyphs substitute for game content."),
    ]
    yy = 205 * mm
    for heading, body in rules:
        c.setFillColor(RED)
        c.circle(115 * mm, yy - 2 * mm, 1.6 * mm, fill=1, stroke=0)
        p(c, heading, 121 * mm, yy + 1 * mm, 63 * mm, 9, INK, True)
        used = p(c, body, 121 * mm, yy - 8 * mm, 63 * mm, 7.8, MUTED, False, 10.5)
        yy -= max(30 * mm, used + 14 * mm)
    footer(c, 4)


def page_five(c):
    title(c, "Import + freshness", "A useful first screen before JSON exists", "The tracker explains the source, opens Clash directly, and makes snapshot age visible.")
    phone(c, 18 * mm, 29 * mm, 78 * mm, 206 * mm)
    c.setFillColor(GOLD)
    c.circle(57 * mm, 191 * mm, 18 * mm, fill=1, stroke=0)
    c.setFillColor(white)
    c.setFont("AppBold", 14)
    c.drawCentredString(57 * mm, 187 * mm, "BUILDER")
    p(c, "Import account data", 26 * mm, 162 * mm, 62 * mm, 14, INK, True, 17, TA_CENTER)
    p(c, "Copy your account JSON in Clash of Clans. It appears below the API token in Settings → More Settings.", 27 * mm, 143 * mm, 60 * mm, 8, MUTED, False, 11, TA_CENTER)
    c.setFillColor(RED)
    c.roundRect(29 * mm, 103 * mm, 56 * mm, 12 * mm, 6 * mm, fill=1, stroke=0)
    c.setFillColor(white)
    c.setFont("AppBold", 8)
    c.drawCentredString(57 * mm, 107 * mm, "Paste clipboard")
    card(c, 29 * mm, 86 * mm, 56 * mm, 12 * mm, white, 6 * mm, LINE)
    c.setFillColor(INK)
    c.drawCentredString(57 * mm, 90 * mm, "Open More Settings")
    p(c, "Paste JSON remains available as a secondary path.", 28 * mm, 73 * mm, 58 * mm, 7, MUTED, False, 10, TA_CENTER)
    p(c, "FRESHNESS SURFACES", 110 * mm, 217 * mm, 75 * mm, 8, RED, True)
    card(c, 110 * mm, 170 * mm, 80 * mm, 35 * mm)
    p(c, "Magic Jr.", 118 * mm, 195 * mm, 57 * mm, 11, INK, True)
    p(c, "#2J8V28GV0 · TH18 / BH10", 118 * mm, 185 * mm, 57 * mm, 7.5, MUTED)
    pill(c, 118 * mm, 174 * mm, "Updated 18 minutes ago", HexColor("#EEF5FF"), BLUE)
    card(c, 110 * mm, 118 * mm, 80 * mm, 39 * mm, SURFACE)
    p(c, "Account picker", 118 * mm, 147 * mm, 60 * mm, 10, INK, True)
    p(c, "Every saved account shows its capture date/time, so stale exports are visible before selection.", 118 * mm, 137 * mm, 62 * mm, 8, MUTED, False, 11)
    card(c, 110 * mm, 66 * mm, 80 * mm, 39 * mm, SURFACE)
    p(c, "Live age label", 118 * mm, 95 * mm, 60 * mm, 10, INK, True)
    p(c, "Only the small timestamp listens to the clock. The page and its grids stay still.", 118 * mm, 85 * mm, 62 * mm, 8, MUTED, False, 11)
    footer(c, 5)


def page_six(c):
    title(c, "Verification", "What changed, and how it was checked", "App and shared system were validated independently.")
    rows = [
        ("ClashKingApp", "Tracker parser/repository tests", "6 passed", GREEN),
        ("ClashKingApp", "Tracker source analysis", "No issues", GREEN),
        ("ClashKingApp", "Localization generation", "Generated", BLUE),
        ("DevKit", "Flutter component tests", "9 passed", GREEN),
        ("DevKit", "Manifest + token checks", "Passed", GREEN),
        ("Both repos", "Whitespace / patch validation", "Clean", GREEN),
    ]
    y = 219 * mm
    for repo, check, result, color in rows:
        card(c, 18 * mm, y - 17 * mm, 174 * mm, 15 * mm, white, 3 * mm)
        p(c, repo, 24 * mm, y - 7 * mm, 35 * mm, 8, MUTED, True)
        p(c, check, 63 * mm, y - 7 * mm, 77 * mm, 9, INK, True)
        pill(c, 151 * mm, y - 13 * mm, result, Color(color.red, color.green, color.blue, alpha=0.12), color)
        y -= 20 * mm
    p(c, "IMPLEMENTATION MAP", 18 * mm, 87 * mm, 80 * mm, 8, RED, True)
    files = [
        ("upgrade_tracker_page.dart", "virtualized tabs, scoped timers, onboarding, freshness, modal"),
        ("upgrade_tracker_models.dart", "memoized item queries and summaries"),
        ("upgrade_tracker_parser.dart", "cached static lookup and O(1) collection dedupe"),
        ("upgrade_tracker_repository.dart", "snapshot cache, one-pass imports, capture metadata"),
        ("clashking_design_system.dart", "semantic type, color, density, and tracker primitives"),
    ]
    yy = 76 * mm
    for name, purpose in files:
        c.setFillColor(SURFACE)
        c.roundRect(18 * mm, yy - 8 * mm, 174 * mm, 10 * mm, 2 * mm, fill=1, stroke=0)
        p(c, name, 23 * mm, yy, 62 * mm, 7.5, INK, True)
        p(c, purpose, 88 * mm, yy, 97 * mm, 7.2, MUTED)
        yy -= 12 * mm
    footer(c, 6)


def main():
    font_setup()
    c = Canvas(OUT, pagesize=A4)
    for draw in (page_one, page_two, page_three, page_four, page_five, page_six):
        draw(c)
        c.showPage()
    c.save()


if __name__ == "__main__":
    main()
