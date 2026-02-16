# Checklista testów manualnych – UX statystyk (Zadania vs TaskDetails)

## 1. Ekran „Zadania”

- [ ] **Zmiana kategorii** – po wyborze innej kategorii (chipy) karta „Podsumowanie kategorii” zmienia nazwę i sumę czasu („Łącznie: …”) na dane nowej kategorii.
- [ ] **Zmiana okresu** – po zmianie okresu w dropdownie (Wszystkie / Dzisiaj / Ostatnie 7 dni / itd.) karta „Podsumowanie kategorii” i lista zadań aktualizują się (suma czasu i lista zadań zgodne z wybranym okresem).
- [ ] **Klik „Statystyki”** – tap na kartę „Podsumowanie kategorii” otwiera ekran „Statystyki kategorii” z prawidłową kategorią (nazwa, kolor) i zakresem (Wszystkie / Ten miesiąc) ustawionym domyślnie zgodnie z okresem z listy zadań (np. wybór „Ten miesiąc” na liście → domyślnie „Ten miesiąc” na ekranie statystyk).
- [ ] **Brak kategorii** – gdy nie ma wybranej kategorii, karta „Podsumowanie kategorii” się nie wyświetla (lub jest stan „disabled”).
- [ ] **Empty** – gdy w danym okresie brak czasu w kategorii, karta pokazuje „Łącznie: 0m” i nadal pozwala wejść na ekran statystyk (tam empty state).

## 2. Ekran „Statystyki kategorii”

- [ ] **Zmiana zakresu** – przełączenie „Wszystkie” / „Ten miesiąc” przelicza wszystkie statystyki i ranking.
- [ ] **Empty state** – przy braku ukończonych sesji w zakresie wyświetla się komunikat „Brak ukończonych sesji w tym zakresie”, bez usuwania wykresów (placeholder/0).

## 3. Ekran „Task Details” (szczegóły zadania)

- [ ] **Brak statystyk kategorii** – w sekcji „Statystyki” nie ma już panelu/dashboardu statystyk kategorii (wykresy, ranking itd.).
- [ ] **Tylko statystyki zadania** – sekcja „Statystyki” zawiera wyłącznie dane tego zadania: Status (np. „X sesje ukończone”) oraz Notatki z sesji (jeśli były).

## 4. Opcjonalnie

- [ ] **Ustawienia widgetów** – w ustawieniach włącz/wyłącz poszczególne karty na ekranie „Statystyki kategorii”; lista kart na tym ekranie buduje się dynamicznie wg tych ustawień.
