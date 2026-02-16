# Checklista testów manualnych - Statystyki kategorii

## Przygotowanie
1. ✅ Uruchom aplikację
2. ✅ Utwórz kategorię testową
3. ✅ Utwórz zadanie przypisane do kategorii
4. ✅ Utwórz kilka zakończonych sesji dla tego zadania (różne daty)

## Testy podstawowe

### 1. Otwieranie panelu statystyk
- [ ] Przejdź do szczegółów zadania z kategorią
- [ ] Kliknij kafelek "Statystyki"
- [ ] Panel powinien się rozwinąć z animacją (AnimatedSize)
- [ ] Panel powinien pokazywać statystyki dla kategorii tego zadania

### 2. Przełącznik zakresu czasowego
- [ ] Domyślnie wybrany jest "Wszystkie"
- [ ] Kliknij "Ten miesiąc"
- [ ] Statystyki powinny się przeliczyć (loading state)
- [ ] Wszystkie metryki powinny pokazywać dane tylko z bieżącego miesiąca
- [ ] Przełącz z powrotem na "Wszystkie"
- [ ] Statystyki powinny pokazywać wszystkie dane

### 3. Karty statystyk - Podsumowanie

#### Łączny czas
- [ ] Karta "Łączny czas" pokazuje czas w formacie "Xh Ym" (np. "2h 15m")
- [ ] Wartość zmienia się przy zmianie zakresu

#### Średnia długość sesji
- [ ] Karta "Średnia długość sesji" pokazuje średnią w formacie "Xmin Ys"
- [ ] Wartość jest poprawnie obliczona (suma czasu / liczba sesji)

#### Porównanie do średniej
- [ ] Karta pokazuje udział procentowy kategorii w całkowitym czasie
- [ ] Pokazuje różnicę vs średnia na kategorię (+/- %)
- [ ] Jeśli brak innych kategorii, karta może nie być widoczna lub pokazywać "—"

### 4. Wykresy

#### Wykres ostatnich 7 dni
- [ ] Wykres słupkowy pokazuje 7 słupków (ostatnie 7 dni)
- [ ] Słupki mają kolor kategorii
- [ ] Etykiety dni są czytelne (Pon, Wt, Śr...)
- [ ] Tooltip przy dotknięciu pokazuje minutę i liczbę sesji
- [ ] Wysokość słupków odpowiada wartościom

#### Trend 30 dni
- [ ] Wykres liniowy pokazuje ostatnie 30 dni
- [ ] Wskaźnik trendu pokazuje procentową zmianę vs poprzednie 30 dni
- [ ] Jeśli brak danych poprzednich, pokazuje "—"
- [ ] Kolor wskaźnika: zielony dla dodatniego, czerwony dla ujemnego
- [ ] Tooltip przy dotknięciu pokazuje datę i minutę

### 5. Wzorce

#### Najbardziej produktywny dzień tygodnia
- [ ] Karta pokazuje dzień tygodnia (np. "Poniedziałek")
- [ ] Dzień jest poprawnie obliczony (najwięcej minut w zakresie)

#### Streak
- [ ] Karta pokazuje liczbę dni streak (np. "5 dni")
- [ ] Streak liczy tylko dni z minimum 2 sesjami i >=10 min
- [ ] Dla "Ten miesiąc" streak jest ograniczony do dni w miesiącu
- [ ] Dla "Wszystkie" streak liczy wstecz od ostatniego dnia z aktywnością

#### Najczęstsza godzina pracy
- [ ] Karta pokazuje zakres godzin (np. "21:00-22:00")
- [ ] Mini-heatmapa pokazuje histogram 24 godzin
- [ ] Intensywność koloru odpowiada liczbie sesji
- [ ] Etykiety godzin są czytelne

### 6. Ranking kategorii
- [ ] Karta pokazuje ranking wszystkich kategorii
- [ ] Kategorie są posortowane po łącznym czasie (desc)
- [ ] Aktualna kategoria jest wyróżniona (ramka, kolor)
- [ ] Pokazuje pozycję aktualnej kategorii (np. "Pozycja 2 z 5")
- [ ] Dla "Ten miesiąc" ranking jest tylko dla tego miesiąca
- [ ] Dla "Wszystkie" ranking jest dla całej historii

## Testy edge cases

### Brak danych
- [ ] Jeśli brak ukończonych sesji w zakresie, pokazuje "Brak ukończonych sesji w tym zakresie"
- [ ] Wykresy nie są wyświetlane jeśli brak danych
- [ ] Karty pokazują sensowne wartości (0, "—", itp.)

### Zadanie bez kategorii
- [ ] Jeśli zadanie nie ma kategorii, panel pokazuje komunikat
- [ ] Komunikat informuje, że statystyki są dostępne tylko dla zadań z kategorią

### Puste zakresy
- [ ] "Ten miesiąc" bez danych pokazuje empty state
- [ ] "Wszystkie" bez danych pokazuje empty state

## Testy ustawień

### Toggle statystyk
- [ ] Przejdź do Ustawienia → Statystyki kategorii
- [ ] Wszystkie toggle'y są domyślnie włączone
- [ ] Wyłącz "Łączny czas"
- [ ] Wróć do szczegółów zadania → Statystyki
- [ ] Karta "Łączny czas" nie jest widoczna
- [ ] Włącz z powrotem
- [ ] Karta pojawia się ponownie
- [ ] Powtórz dla innych toggle'ów

### Dynamiczna lista widgetów
- [ ] Wyłącz kilka toggle'ów
- [ ] Panel statystyk pokazuje tylko włączone karty
- [ ] Sekcje są ukryte jeśli wszystkie karty w sekcji są wyłączone
- [ ] Jeśli wszystkie wyłączone, pokazuje komunikat

## Testy wydajności

### Cache i przeliczanie
- [ ] Przy pierwszym otwarciu panelu pokazuje loading
- [ ] Po załadowaniu, przełączenie zakresu przelicza dane
- [ ] Po zamknięciu i ponownym otwarciu, dane są cache'owane (szybkie ładowanie)
- [ ] Po dodaniu nowej sesji, statystyki się aktualizują

### Duże ilości danych
- [ ] Utwórz wiele sesji (100+) dla kategorii
- [ ] Panel powinien się otworzyć w rozsądnym czasie (<2s)
- [ ] Wykresy powinny być responsywne

## Testy UI/UX

### Dark mode
- [ ] Wszystkie karty są czytelne w dark mode
- [ ] Kolory wykresów są widoczne
- [ ] Teksty mają odpowiedni kontrast

### Responsywność
- [ ] Panel wygląda dobrze na małych ekranach
- [ ] Wykresy są czytelne na różnych rozdzielczościach
- [ ] Karty nie wychodzą poza ekran

### Animacje
- [ ] Rozwijanie panelu jest płynne (AnimatedSize)
- [ ] Przełączanie zakresu pokazuje loading state
- [ ] Brak migotania przy przełączaniu

## Testy integracyjne

### Relacje z innymi ekranami
- [ ] Statystyki nie wpływają na inne ekrany
- [ ] Usunięcie sesji aktualizuje statystyki
- [ ] Zmiana kategorii zadania aktualizuje statystyki
- [ ] Usunięcie kategorii nie powoduje crash'a

## Checklista końcowa

- [ ] Wszystkie metryki są poprawnie obliczone
- [ ] Wszystkie wykresy działają poprawnie
- [ ] Toggle'y w ustawieniach działają
- [ ] Edge cases są obsłużone
- [ ] Wydajność jest akceptowalna
- [ ] UI jest czytelne i estetyczne
- [ ] Brak błędów w konsoli
- [ ] Aplikacja nie crash'uje w żadnym scenariuszu
