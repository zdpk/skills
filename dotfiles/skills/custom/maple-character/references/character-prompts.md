# Character Sheet Prompts

두 가지 시트 타입을 지원: **body** (전신 3방향)과 **expression** (표정 시트).

---

## Body Sheet (전신 — 메이플스토리 3방향)

메이플스토리 스타일의 3방향 전신 스프라이트를 **2x2 그리드**로 생성.

### 메이플스토리 방향 체계

메이플스토리에는 "정면"이라는 개념이 없다. 3가지 방향만 존재:

| 방향 | 설명 | 시각적 특징 |
|------|------|------------|
| 3/4 앞 | 메이플 기본 서있는 포즈 | 양쪽 눈 보임, 약간 비스듬한 앞모습 (완전 정면 아님) |
| 뒤 | 완전 후면 | 뒷통수와 의상 뒷면만 보임 |
| 3/4 좌/우 | 정면에 가까운 측면 | 완전한 옆모습(90도)이 아님. ~30-45도 돌아간 형태, 한쪽 눈과 얼굴 일부 보임 |

**주의**: 좌/우가 완전 측면(프로필)이 아니라 **정면에 가까운 측면**이다. 코와 한쪽 눈이 보이고, 몸통도 약간 비스듬히 보인다.

### Grid Layout Instruction

프롬프트에 반드시 포함할 그리드 구조:

```
The image is divided into exactly 4 equal quadrants by one horizontal line and one vertical line crossing at the center, forming a 2x2 grid. Each quadrant contains EXACTLY ONE full-body pose of the same character, centered horizontally and vertically within the cell. NO text labels.

Top-left = MapleStory default standing pose (three-quarter front view, both eyes visible, body slightly angled — NOT a straight-on front view)
Top-right = BACK view (character facing completely away, showing back of head and outfit)
Bottom-left = three-quarter LEFT view (character turned ~30-45 degrees to the left — NOT a full 90-degree side profile. One eye and partial face still visible, body angled)
Bottom-right = three-quarter RIGHT view (mirror of left — character turned ~30-45 degrees to the right, one eye and partial face visible)
```

## Style Templates

### Pixel Art (Default)

```
Professional MapleStory 2D pixel art character sprite sheet. The image is divided into exactly 4 equal quadrants by one horizontal line and one vertical line crossing at the center. EXACTLY ONE character centered in each cell. NO text labels. Top-left: MapleStory default standing pose (three-quarter front, both eyes visible, body slightly angled). Top-right: back view (facing completely away, back of head). Bottom-left: three-quarter left view (turned ~30-45 degrees left, NOT full side profile, one eye and partial face visible). Bottom-right: three-quarter right view (mirror of left, turned ~30-45 degrees right). Chibi proportions with 3-head-to-body ratio, large expressive eyes, small cute body. Clean pixel outlines, vibrant anime-game colors, flat cel-shading. {character_description}. CRITICAL: identical character design, outfit, hair, and colors in all 4 cells — only the viewing angle differs. Each character perfectly centered in its cell. White background per cell.
```

### Chibi

```
Professional cute chibi character sprite sheet in MapleStory style. The image is divided into exactly 4 equal quadrants by one horizontal line and one vertical line crossing at the center. EXACTLY ONE character centered in each cell. NO text labels. Top-left: MapleStory default standing pose (three-quarter front, both eyes visible, body slightly angled). Top-right: back view (facing completely away, back of head). Bottom-left: three-quarter left view (turned ~30-45 degrees left, NOT full side profile, one eye and partial face visible). Bottom-right: three-quarter right view (mirror of left, turned ~30-45 degrees right). Big head with huge expressive eyes, tiny body (2.5-3 head ratio). Soft cel-shading, smooth clean lines. {character_description}. CRITICAL: identical character design, outfit, hair, and colors in all 4 cells — only the viewing angle differs. Each character perfectly centered in its cell. White background per cell.
```

### Semi-Realistic

```
Professional semi-realistic anime character sprite sheet with MapleStory influence. The image is divided into exactly 4 equal quadrants by one horizontal line and one vertical line crossing at the center. EXACTLY ONE character centered in each cell. NO text labels. Top-left: MapleStory default standing pose (three-quarter front, both eyes visible, body slightly angled). Top-right: back view (facing completely away, back of head). Bottom-left: three-quarter left view (turned ~30-45 degrees left, NOT full side profile, one eye and partial face visible). Bottom-right: three-quarter right view (mirror of left, turned ~30-45 degrees right). Anime proportions (4-5 head ratio) with detailed rendering, soft lighting, clean linework. {character_description}. CRITICAL: identical character design, outfit, hair, and colors in all 4 cells — only the viewing angle differs. Each character perfectly centered in its cell. White background per cell.
```

## Character Description Components

When building `{character_description}`, include these elements:

| Component | Example |
|-----------|---------|
| Hair | "pink twin-tail hair", "short blue spiky hair" |
| Eyes | "large green eyes", "determined red eyes" |
| Outfit top | "blue crop top with white trim", "dark hoodie" |
| Outfit bottom | "green pleated skirt", "black cargo pants" |
| Class/role | "rogue class", "mage with staff", "archer" |
| Accessories | "pointy elf ears", "cat ears headband", "wing cape" |
| Weapon | "dual daggers", "wooden staff", "bow and quiver" |
| Special | "glowing aura", "floating pet beside character" |

## Prompt Construction

Combine in this order:
1. Style template (pixel_art / chibi / semi_realistic) — already includes grid structure + direction descriptions
2. Character description fills `{character_description}` placeholder
3. Any additional modifiers appended at end

### Example: Full Prompt

```
Professional MapleStory 2D pixel art character sprite sheet. The image is divided into exactly 4 equal quadrants by one horizontal line and one vertical line crossing at the center. EXACTLY ONE character centered in each cell. NO text labels. Top-left: MapleStory default standing pose (three-quarter front, both eyes visible, body slightly angled). Top-right: back view (facing completely away, back of head). Bottom-left: three-quarter left view (turned ~30-45 degrees left, NOT full side profile, one eye and partial face visible). Bottom-right: three-quarter right view (mirror of left, turned ~30-45 degrees right). Chibi proportions with 3-head-to-body ratio, large expressive eyes, small cute body. Clean pixel outlines, vibrant anime-game colors, flat cel-shading. Pink twin-tail haired elf girl with pointy ears, large green eyes, wearing blue crop top with white trim and green pleated skirt, rogue class with dual daggers. CRITICAL: identical character design, outfit, hair, and colors in all 4 cells — only the viewing angle differs. Each character perfectly centered in its cell. White background per cell.
```

---

## Expression Sheet (표정 시트)

동일 캐릭터 얼굴의 **다양한 감정 표현**을 그리드로 생성. 라벨 없음.

### Grid Layout Instruction

프롬프트에 반드시 포함할 그리드 구조 지시:

```
Multiple facial expressions of the SAME character arranged in a grid with clear thin black dividing lines separating each cell. Each cell shows the character's face and upper body (bust shot) with a different emotion. All cells are the same size with equal spacing. NO text labels. The character's face shape, hair style, hair color, eye shape, and accessories must be IDENTICAL across all cells — only the facial expression changes. Clean white background in every cell.
```

### Expression Style Templates

#### Pixel Art (Default)

```
Professional MapleStory 2D pixel art character expression reference sheet. Multiple emotions of the SAME character's face in a grid with thin black dividing lines. NO text labels. Face and upper body close-up (bust shot). Chibi face with large expressive eyes, exaggerated clear expressions for each emotion. Expressions include: neutral, happy, sad, angry, surprised, embarrassed, smirk, crying, sleepy. Clean pixel outlines, vibrant colors, flat cel-shading. {character_description}. CRITICAL: identical face shape, hair style, hair color, eye shape, and accessories in ALL cells — only the expression changes. Clean white background per cell. Game sprite expression sheet.
```

#### Chibi

```
Professional cute chibi character expression reference sheet in MapleStory style. Multiple emotions of the SAME character's face in a grid with thin black dividing lines. NO text labels. Face and upper body close-up (bust shot). Big head, huge expressive eyes, exaggerated but adorable expressions. Expressions include: neutral, happy, sad, angry, surprised, embarrassed, smirk, crying, sleepy. Soft cel-shading, smooth lines. {character_description}. CRITICAL: identical face shape, hair style, hair color, and accessories in ALL cells — only the expression changes. White background, character expression reference sheet.
```

#### Semi-Realistic

```
Professional semi-realistic anime character expression reference sheet with MapleStory influence. Multiple emotions of the SAME character's face in a grid with thin dividing lines. NO text labels. Face and upper body close-up (bust shot). Detailed facial rendering with nuanced expressions, soft lighting, clean linework. Expressions include: neutral, happy, sad, angry, surprised, embarrassed, smirk, crying, sleepy. {character_description}. CRITICAL: identical face shape, hair style, hair color, and accessories in ALL cells — only the expression changes. Clean white background, professional character expression reference.
```

### Expression Visual Descriptions

각 표정에 대한 시각적 설명 (프롬프트 보강용 — 필요시 개별 표정 상세 지시에 추가):

| Expression | Visual Cues |
|------------|-------------|
| neutral | relaxed face, slight gentle smile, calm eyes |
| happy | wide open smile, sparkling eyes, raised cheeks |
| sad | downturned mouth, teary eyes, drooping eyebrows |
| angry | furrowed brows, clenched teeth, intense eyes |
| surprised | wide open eyes, open mouth, raised eyebrows |
| embarrassed | blushing cheeks, averted gaze, shy smile |
| smirk | one-sided grin, confident half-closed eyes |
| crying | streaming tears, scrunched face, open mouth wailing |
| sleepy | half-closed droopy eyes, slight open mouth, drowsy |

### Tips for Expression Sheets

1. **기존 캐릭터 이미지를 ingredient로**: body sheet가 이미 있으면 업로드하여 얼굴 일관성 유지
2. **얼굴 클로즈업 강조**: 템플릿에 이미 "face and upper body close-up (bust shot)" 포함
3. **Aspect ratio**: `1:1` 권장 (그리드에 적합)
4. **표정 수**: 모델이 자동으로 적절한 그리드 크기 결정 (9~12개)

---

## Tips for Better Results

1. **Ingredient 이미지 필수**: 텍스트만으로는 캐릭터 일관성 유지 어려움. 기존 캐릭터 이미지를 ingredient로 업로드할 것
2. **메이플 3방향 체계**: 정면(FRONT) 없음. 3/4 앞모습 + 뒤 + 3/4 좌우
3. **3/4 측면 강조**: "NOT full side profile" + "turned ~30-45 degrees" — 완전 측면이 아닌 정면에 가까운 측면
4. **"no duplicate angles" 명시**: 같은 방향 중복 방지를 위해 반드시 포함
5. **"EXACTLY ONE character centered" 명시**: 각 셀에 캐릭터 1개만, 중앙 정렬
6. **"NO text labels" 명시**: 방향 라벨 텍스트 불필요
7. **그리드 구조 물리적 묘사**: "horizontal line and vertical line crossing at center" — 추상적 "2x2 grid"보다 효과적
8. **"CRITICAL" + "SAME" 강조**: 셀 간 캐릭터 동일성을 위해 대문자 강조 키워드 유지
9. **구체적 외형 묘사**: 머리 색상, 의상 색상, 고유 액세서리를 상세히 기술
10. **Aspect ratio**: `1:1` 권장 (정사각형 그리드에 최적)
11. **MapleStory 직접 언급**: 모델이 타겟 스타일 이해에 도움
12. **반복 생성**: 첫 결과가 완벽하지 않을 수 있음 — 설명을 조정하며 반복
