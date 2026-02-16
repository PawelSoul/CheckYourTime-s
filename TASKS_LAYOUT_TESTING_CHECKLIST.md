# Checklista testów manualnych - Nowy layout ekranu Zadania

## Przygotowanie
1. ✅ Uruchom aplikację
2. ✅ Przejdź do ekranu "Zadania"
3. ✅ Upewnij się, że masz przynajmniej jedną kategorię z ukończonymi zadaniami

## Testy podstawowe

### 1. Layout ogólny
- [ ] Ekran nie ma już podziału na 2 kolumny (lewa/prawa)
- [ ] Kategorie są wyświetlone poziomo na górze (scroll w poziomie)
- [ ] Lista zadań zajmuje pełną szerokość ekranu
- [ ] Brak pionowej linii separatora między kategoriami a zadaniami

### 2. Poziomy scroll kategorii (CategoryChipsBar)
- [ ] Kategorie są wyświetlone jako chipsy/pills w jednej linii
- [ ] Każdy chip ma małą kropkę w kolorze kategorii + nazwę
- [ ] Poziomy scroll działa (przesuwanie w lewo/prawo)
- [ ] Aktywna kategoria jest wyróżniona:
  - [ ] Delikatne wypełnienie tła (jaśniejsze)
  - [ ] Cienka ramka w kolorze kategorii
  - [ ] Subtelny glow/outline
  - [ ] Tekst wyraźniejszy (bold)
- [ ] Nieaktywne kategorie mają neutralne tło i mniejszy kontrast
- [ ] Tapnięcie w kategorię zmienia aktywną kategorię
- [ ] Lista zadań przeładowuje się po zmianie kategorii (AnimatedSwitcher)

### 3. Pasek filtra okresu (SimpleDateFilterBar)
- [ ] Pasek jest widoczny tylko gdy wybrana jest kategoria
- [ ] Zawiera label "Okres:" + SegmentedButton z opcjami "Wszystkie" / "Ten miesiąc"
- [ ] Domyślnie wybrane jest "Wszystkie"
- [ ] Przełączenie na "Ten miesiąc" filtruje zadania tylko z bieżącego miesiąca
- [ ] Przełączenie z powrotem na "Wszystkie" pokazuje wszystkie zadania
- [ ] Lista zadań reaguje na zmianę filtra

### 4. Lista zadań (MinimalTaskCard)
- [ ] Pokazują się TYLKO ukończone zadania (isArchived == true)
- [ ] Karty są minimalistyczne, bez dużych elementów
- [ ] Każda karta zawiera:
  - [ ] Kolorowa kropka kategorii (8x8px)
  - [ ] Tytuł zadania (bold) w pierwszym wierszu
  - [ ] Data wykonania (dd.MM.yyyy) w drugim wierszu
  - [ ] Godzina rozpoczęcia i zakończenia (HH:mm — HH:mm) w drugim wierszu
  - [ ] Format: "13.02.2026 • 23:04 — 23:48"
- [ ] Jeśli brak godziny zakończenia, pokazuje tylko godzinę rozpoczęcia
- [ ] Cienka linia akcentu na dole karty (1.5px) w kolorze kategorii
- [ ] Odstępy między kartami są odpowiednie (8px)
- [ ] Zaokrąglenia kart są subtelne (12px)
- [ ] Tapnięcie w kartę otwiera TaskDetailsPage (bez zmian)

### 5. Empty state
- [ ] Jeśli brak kategorii: komunikat "Brak kategorii..."
- [ ] Jeśli brak wybranej kategorii: komunikat "Wybierz kategorię powyżej..."
- [ ] Jeśli brak ukończonych zadań w kategorii: komunikat "Brak ukończonych zadań w tej kategorii"
- [ ] Jeśli brak zadań w wybranym okresie: komunikat "Brak ukończonych zadań w wybranym okresie"
- [ ] Empty state ma ikonę i tekst wyśrodkowane

### 6. Animacje
- [ ] Zmiana kategorii powoduje płynne przejście listy zadań (AnimatedSwitcher)
- [ ] Chipsy kategorii mają subtelne animacje przy zmianie stanu
- [ ] Tapnięcie w chip powoduje animowane przejście (InkWell splash minimalny)
- [ ] Brak migotania przy przełączaniu

## Testy funkcjonalności

### Filtrowanie zadań
- [ ] Tylko ukończone zadania są pokazywane (isArchived == true)
- [ ] Filtr okresu działa poprawnie:
  - [ ] "Wszystkie" pokazuje wszystkie ukończone zadania
  - [ ] "Ten miesiąc" pokazuje tylko zadania z bieżącego miesiąca
- [ ] Zmiana filtra nie resetuje wybranej kategorii

### Wybór kategorii
- [ ] Wybór kategorii przeładowuje listę zadań dla tej kategorii
- [ ] Wybrana kategoria jest zapamiętywana (nie resetuje się przy przejściu do innego ekranu)
- [ ] Long press na kategorię otwiera menu opcji (bez zmian)

### Nawigacja
- [ ] Kliknięcie w kartę zadania otwiera TaskDetailsPage
- [ ] Przekazywane są poprawne dane (task, categoryColorHex)
- [ ] Powrót z TaskDetailsPage zachowuje wybraną kategorię i filtr

## Testy UI/UX

### Dark mode
- [ ] Wszystkie elementy są czytelne w dark mode
- [ ] Kolory kategorii są widoczne
- [ ] Kontrast tekstu jest odpowiedni
- [ ] Tła kart są subtelne (nie za jasne)

### Responsywność
- [ ] Poziomy scroll kategorii działa na małych ekranach
- [ ] Karty zadań nie wychodzą poza ekran
- [ ] Tekst nie jest obcięty
- [ ] Wszystko jest czytelne na różnych rozdzielczościach

### Wydajność
- [ ] Lista zadań ładuje się szybko
- [ ] Scroll jest płynny
- [ ] Brak lagów przy zmianie kategorii
- [ ] AnimatedSwitcher działa płynnie

## Testy edge cases

### Brak danych
- [ ] Brak kategorii - pokazuje komunikat
- [ ] Brak zadań w kategorii - pokazuje empty state
- [ ] Brak zadań w okresie - pokazuje komunikat o okresie

### Puste wartości
- [ ] Zadanie bez sesji - pokazuje tylko datę i godzinę utworzenia
- [ ] Zadanie bez godziny zakończenia - pokazuje tylko godzinę rozpoczęcia
- [ ] Kategoria bez koloru - używa domyślnego koloru

## Checklista końcowa

- [ ] Layout jest minimalistyczny i czytelny
- [ ] Wszystkie funkcje działają jak wcześniej
- [ ] Tylko ukończone zadania są pokazywane
- [ ] Filtr okresu działa poprawnie
- [ ] Animacje są subtelne i płynne
- [ ] UI jest responsywne
- [ ] Brak błędów w konsoli
- [ ] Aplikacja nie crash'uje
