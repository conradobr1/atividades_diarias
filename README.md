# Atividades diárias — Aula 15

Aplicativo Android em Flutter e Dart. Registra a data e a descrição das
atividades em SQLite por meio de um servidor PHP e lista os registros por mês.

## Rodar no emulador Android

1. Execute `iniciar_servidor.cmd` no Windows. O servidor usa PHP 8.1+
   com `pdo_sqlite` e `mbstring`, disponíveis no PHP do XAMPP.
2. Abra um emulador Android no Android Studio. Instale o APK de demonstração
   fornecido separadamente ou execute `flutter run` na pasta do projeto.
3. Digite a data em DD/MM/AAAA e a descrição. Toque em **Salvar atividade**
   e use as setas para consultar outros meses.

O aplicativo usa `http://10.0.2.2:8080` no emulador, que aponta para o servidor
na máquina Windows. Os registros ficam em `server/atividades.sqlite`.

## Compilar o código-fonte

Use Flutter 3.16.9, Android SDK e JDK 17. Execute `flutter pub get` e
`flutter build apk --debug`. O APK da compilação padrão fica em
`build/app/outputs/flutter-apk/app-debug.apk`.

Para usar um aparelho Android físico via USB, inicie o servidor no computador,
conecte o aparelho com depuração USB e execute `adb reverse tcp:8080 tcp:8080`.
Em seguida, execute
`flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080`.
