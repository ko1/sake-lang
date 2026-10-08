-- char builds text from code points
SELECT char(72, 101, 108, 108, 111);
SELECT char(), typeof(char()), length(char());
SELECT char(48 + 7), typeof(char(65));
SELECT length(char(32, 32, 126)), char(126);
SELECT CHAR(97) || Char(98);
