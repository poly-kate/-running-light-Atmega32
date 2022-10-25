# Организация аналогового ввода-вывода: АЦП и ШИМ
Разрядам регистров PORTA, PORTB и PORTC ставится в соответствие
отрезок [0–23] (0 7 ~ PA0–PA7, 8 15 ~ PB0 PB7, 16 23 ~ PC0 PC7). На данном
отрезке отображается «бегущий огонь» из набора горящих светодиодов. Для
гирлянды существует базовое значение (набор одновременно горящих
светодиодов), которое с определённой частотой циклически сдвигается на
определённый шаг. Параметрами гирлянды являются:
- базовое значение (b) – положительное трёхбайтное число, которое
циклически сдвигается и отображается на регистрах PORTA–PORTC.
Параметрами являются числа b0, b1 и b2 (отдельные байты базового значения),
лежащие в диапазоне [0-255];
- величина шага (h), на которую циклически сдвигается базовое значение
каждый такт гирлянды. Допустимый диапазон величины шага [-12;12];
- частота смены состояний (p). Допустимый диапазон частоты смены
состояний [1-15] (раз / в 2 секунды);
- начальное смещение (d), определяющее с каким значением смещения
начинает работать гирлянда при запуске программы. Допустимый диапазон
начального смещения [-12;12].
Гирлянда работает по следующему правилу: {si = (si-1 << h); s0 = (b << d)}.
Настраиваемые параметры: b0; b1; b2
Неизменяемые параметры: h=1; p=5; d=0
