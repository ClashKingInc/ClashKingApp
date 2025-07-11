// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'İstatistikleri takip etmek, klanları yönetmek ve performansı analiz etmek için en iyi Clash of Clans arkadaşınız.';

  @override
  String get generalLoading => 'Yükleniyor...';

  @override
  String get loadingVillages => 'Köyleriniz yükleniyor...';

  @override
  String get loadingClanData => 'Klan verileri getiriliyor...';

  @override
  String get loadingWarStats => 'Savaş istatistikleri analiz ediliyor...';

  @override
  String get loadingLegendsData => 'Efsane verileri hazırlanıyor...';

  @override
  String get loadingCapitalRaids => 'Başkent baskınları yükleniyor...';

  @override
  String get loadingAlmostReady => 'Neredeyse hazır...';

  @override
  String get accountVerificationTitle => 'Hesabı Doğrula';

  @override
  String get accountVerificationMessage =>
      'Bu hesabın sahibi olduğunuzu doğrulamak için API token\'ınızı girin. Bunu Clash of Clans Ayarları > Diğer Ayarlar > API Token\'da bulabilirsiniz.';

  @override
  String get accountVerified => 'Hesap doğrulandı';

  @override
  String get accountNotVerified => 'Hesap doğrulanmadı';

  @override
  String get accountVerifyButton => 'Doğrula';

  @override
  String get accountVerificationSuccess => 'Hesap başarıyla doğrulandı!';

  @override
  String get accountVerificationFailed =>
      'Doğrulama başarısız. Lütfen API token\'ınızı kontrol edin.';

  @override
  String get generalRetry => 'Yeniden dene';

  @override
  String get generalTryAgain => 'Tekrar deneyin';

  @override
  String get generalCancel => 'İptal';

  @override
  String get generalOk => 'Tamam';

  @override
  String get generalApply => 'Uygula';

  @override
  String get generalConfirm => 'Onayla';

  @override
  String get generalManage => 'Yönet';

  @override
  String get generalSettings => 'Ayarlar';

  @override
  String get generalCopiedToClipboard => 'Panoya kopyalandı';

  @override
  String get generalComingSoon => 'Çok yakında!';

  @override
  String generalLastRefresh(String time) {
    return 'Son güncelleme: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Yenileme başarısız oldu: $error';
  }

  @override
  String get generalAll => 'Tümü';

  @override
  String get generalTotal => 'Toplam';

  @override
  String get generalBest => 'En İyi';

  @override
  String get generalWorst => 'En kötü';

  @override
  String get generalAverage => 'Ortalama';

  @override
  String get generalRemaining => 'Kalan';

  @override
  String get generalActive => 'Aktif';

  @override
  String get generalInactive => 'Pasif';

  @override
  String get generalStarted => 'Başladı';

  @override
  String get generalEnded => 'Bitti';

  @override
  String get generalRole => 'Rol';

  @override
  String get generalStats => 'İstatistikler';

  @override
  String get generalFullStats => 'Tüm İstatistikler';

  @override
  String get generalDetails => 'Ayrıntılar';

  @override
  String get generalHistory => 'Geçmiş';

  @override
  String get generalFilters => 'Filtreler';

  @override
  String get generalNotSet => 'Ayarlanmamış';

  @override
  String get generalWarning => 'Uyarı';

  @override
  String get generalNoDataAvailable => 'Veri bulunamadı.';

  @override
  String get authSignUp => 'Kayıt ol';

  @override
  String get authLogin => 'Oturum aç';

  @override
  String get authLogout => 'Oturumu kapat';

  @override
  String get authCreateAccount => 'Hesap Oluştur';

  @override
  String get authJoinClashKing => 'ClashKing\'e katılın';

  @override
  String get authCreateClashKingAccount => 'ClashKing Hesabı Oluştur';

  @override
  String get authCreateAccountToGetStarted =>
      'Başlamak için hesabınızı oluşturun';

  @override
  String get authAlreadyHaveAccount => 'Zaten hesabınız mı var? Oturum açın';

  @override
  String get authConfirmLogout => 'Çıkış yapmak istediğinizden emin misiniz?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Discord ile giriş yap';

  @override
  String get authDiscordContinue => 'Discord ile devam et';

  @override
  String get authDiscordDescription =>
      'Verilerinizi ClashKing Bot ile senkronize edin ve ClashKing\'in tüm potansiyelini ortaya çıkarın!';

  @override
  String get authEmailTitle => 'E-posta';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'Enter your email address';

  @override
  String get authEmailDescription =>
      'Discord\'a erişemiyorsanız e-postayı kullanın veya yalnızca uygulamaya özel özellikleri tercih edin';

  @override
  String get authEmailRequired => 'Lütfen e-posta adresinizi girin';

  @override
  String get authEmailInvalid => 'Lütfen geçerli bir e-posta adresi gir';

  @override
  String get authPasswordLabel => 'Şifre';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authPasswordConfirm => 'Şifreyi Onayla';

  @override
  String get authPasswordRequired => 'Lütfen şifrenizi girin';

  @override
  String get authPasswordConfirmRequired => 'Lütfen şifrenizi onaylayın';

  @override
  String get authPasswordMismatch => 'Şifreler eşleşmiyor';

  @override
  String get authPasswordTooShort => 'Şifre en az 8 karakterden oluşmalıdır';

  @override
  String get authPasswordRequirements =>
      'Şifre şunları içermelidir: büyük harf, küçük harf, rakam ve özel karakter';

  @override
  String get authPasswordForgot => 'Şifrenizi mi unuttunuz?';

  @override
  String get authPasswordForgotDescription =>
      'Enter your email address and we\'ll send you a 6-digit code to reset your password.';

  @override
  String get authPasswordResetSend => 'Send Reset Code';

  @override
  String get authPasswordResetSent => 'Code Sent!';

  @override
  String get authPasswordResetSentDescription =>
      'We\'ve sent a 6-digit reset code to your email address. Please check your inbox and use the code to reset your password.';

  @override
  String get authPasswordReset => 'Reset Password';

  @override
  String get authPasswordResetDescription =>
      'Enter your email, the 6-digit code from the email, and your new password below.';

  @override
  String get authPasswordNew => 'New Password';

  @override
  String get authPasswordConfirmHint => 'Re-enter your new password';

  @override
  String get authPasswordResetConfirm => 'Reset Password';

  @override
  String get authPasswordResetSuccess =>
      'Password reset successful! You can now log in.';

  @override
  String get authPasswordResetContinue => 'Continue to Reset Password';

  @override
  String get authPasswordResetCode => 'Reset Code';

  @override
  String get authPasswordResetCodeHint =>
      'Enter the 6-digit code from your email';

  @override
  String get authPasswordResetCodeRequired => 'Please enter the reset code';

  @override
  String get authPasswordResetCodeInvalid =>
      'Please enter a valid 6-digit code';

  @override
  String get authBackToLogin => 'Back to Login';

  @override
  String get authUsernameLabel => 'Kullanıcı Adı';

  @override
  String get authUsernameRequired => 'Lütfen bir kullanıcı adı girin';

  @override
  String get authUsernameTooShort => 'Kullanıcı adı en az 3 karakter olmalıdır';

  @override
  String get authErrorConnection =>
      'Bir hata oluştu. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.';

  @override
  String get authErrorConnectionRelaunch =>
      'Bir hata oluştu. Lütfen internet bağlantınızı kontrol edin ve uygulamayı yeniden başlatın.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'This email is already registered. Please try logging in instead.';

  @override
  String get authErrorEmailAlreadyPending =>
      'A verification email was already sent to this address. Please check your email or try resending.';

  @override
  String get authErrorEmailInvalidFormat =>
      'Please enter a valid email address.';

  @override
  String get authErrorPasswordWeak =>
      'Password is too weak. Please use a stronger password.';

  @override
  String get authErrorUsernameInvalid =>
      'Username is invalid. Please use only letters, numbers, and underscores.';

  @override
  String get authErrorUsernameExists =>
      'This username is already taken. Please choose a different one.';

  @override
  String get authErrorRegistrationFailed =>
      'Registration failed. Please try again later.';

  @override
  String get authErrorEmailSendFailed =>
      'Failed to send verification email. Please try again later.';

  @override
  String get authErrorRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authErrorServerUnavailable =>
      'Server is temporarily unavailable. Please try again later.';

  @override
  String get authAccountManagement =>
      'Clash of Clans hesaplarınızı ekleyin, kaldırın ve yeniden sıralayın. Tüm özelliklere erişmek için hesaplarınızı doğrulayın.';

  @override
  String get authAccountConnected => 'Bağlı Hesaplar';

  @override
  String get authAccountConnectedStatus => 'Bağlı';

  @override
  String get authAccountNotConnected => 'Bağlı değil';

  @override
  String get authAccountEmailAndPassword => 'E-posta ve Şifre';

  @override
  String get authAccountSecured =>
      'Hesabınız birden fazla kimlik doğrulama yöntemi ile güvence altına alınmıştır';

  @override
  String get authAccountLinkEmail => 'E-posta Hesabını Bağla';

  @override
  String get authAccountAddEmailAuth =>
      'Ek güvenlik için hesabınıza e-posta ve şifre doğrulaması ekleyin.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'E-posta hesabı başarıyla bağlandı!';

  @override
  String get authEmailVerificationTitle => 'Verify Email';

  @override
  String get authEmailVerificationCheckEmail => 'Check Your Email';

  @override
  String get authEmailVerificationSentTo =>
      'We\'ve sent a verification email to:';

  @override
  String get authEmailVerificationInstructions =>
      'Click the link in the email to verify your account. If you don\'t see the email, check your spam folder.';

  @override
  String get authEmailVerificationResend => 'Resend Verification Email';

  @override
  String get authEmailVerificationResendSuccess =>
      'Verification email resent successfully! Please check your email.';

  @override
  String get authEmailVerificationResendFailed =>
      'Failed to resend verification email. Please try again.';

  @override
  String get authEmailVerificationBackToLogin => 'Back to Login';

  @override
  String get authEmailVerificationDevToken =>
      'I have a verification token (Dev)';

  @override
  String get authEmailVerificationDevMode =>
      'Development Mode - Manual Token Input:';

  @override
  String get authEmailVerificationTokenLabel => 'Verification Token';

  @override
  String get authEmailVerificationTokenRequired =>
      'Verification token is required';

  @override
  String get authEmailVerificationVerifyButton => 'Verify Email';

  @override
  String get authEmailVerificationExpired =>
      'Verification expired. Please register again.';

  @override
  String get authEmailVerificationAlreadyVerified =>
      'This email is already verified. Please try logging in instead.';

  @override
  String get authEmailVerificationNoToken =>
      'No pending verification found. Please register first.';

  @override
  String get authEmailVerificationVerifying => 'Verifying your email...';

  @override
  String get authEmailVerificationCodeInstructions =>
      'Enter the 6-digit code sent to your email:';

  @override
  String get authEmailVerificationCodeRequired =>
      'Please enter the 6-digit verification code';

  @override
  String get authEmailVerificationVerify => 'Verify Code';

  @override
  String get helpTitle => 'Yardım mı lazım?';

  @override
  String get helpJoinDiscord => 'Discord\'a Katıl';

  @override
  String get helpEmailUs => 'Bize E-Posta Gönder';

  @override
  String get accountsWelcome => 'Hoşgeldiniz!';

  @override
  String get accountsWelcomeMessage =>
      'Lütfen profilinize bir veya daha fazla Clash of Clans hesabı ekleyin. Daha sonra hesap ekleyebilir veya kaldırabilirsiniz.';

  @override
  String get accountsManageTitle => 'Hesaplarınızı yönetin';

  @override
  String get accountsNoneFound => 'Profilinize bağlı bir hesap bulunamadı';

  @override
  String get accountsPlayerTag => 'Oyuncu Etiketi (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Bir oyuncu etiketi girin';

  @override
  String get accountsAdd => 'Hesap ekle';

  @override
  String get accountsDelete => 'Hesabı sil';

  @override
  String get accountsApiToken => 'Hesap API Tokeni';

  @override
  String get accountsEnterApiToken =>
      'Lütfen hesabınızın API token\'ını girin ve sizin olduğunu doğrulayın. Bunu Clash of Clans Ayarları > Diğer Ayarlar > API Token\'ında bulabilirsiniz.';

  @override
  String get accountsFillAllFields => 'Lütfen tüm alanları doldurun.';

  @override
  String get accountsErrorTagNotExists =>
      'Girilen oyuncu etiketi mevcut değil.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Oyuncu etiketi zaten birine bağlı.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Oyuncu etiketi zaten size bağlı.';

  @override
  String get accountsErrorWrongApiToken => 'Girilen API belirteci yanlış';

  @override
  String get accountsErrorFailedToAdd =>
      'Hesap eklenemedi. Lütfen daha sonra tekrar deneyin.';

  @override
  String get accountsErrorFailedToDelete =>
      'Bağlantı silinemedi. Lütfen daha sonra tekrar deneyin.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Hesapların sırası güncellenemedi.';

  @override
  String get errorTitle =>
      'Oops! Sunucularımız yüzüne bir ateş topu almış olabilir! Bir iyileştirme büyüsü yapıyoruz... Bir dakika içinde tekrar deneyin.';

  @override
  String get errorSubtitle =>
      'Sorun devam ederse, sorunun farkında olup olmadığımızı görmek için Discord Sunucumuzu kontrol edin.';

  @override
  String get errorLoadingVersion => 'Sürüm yüklenirken hata oluştu';

  @override
  String get errorCannotOpenLink => 'Bu bağlantıyı açamıyoruz.';

  @override
  String get errorExitAppToOpenClash =>
      'Clash of Clans\'ı açmak için uygulamadan çıkmak üzeresiniz.';

  @override
  String get playerSearchTitle => 'Oyuncu ara';

  @override
  String get playerSearchPlaceholder => 'Oyuncunun adı veya etiketi';

  @override
  String playerLastActive(String date) {
    return 'Son Aktiflik: $date';
  }

  @override
  String get playerNotTracked =>
      'Bu oyuncu takip edilmiyor. Veriler yanlış olabilir.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Klanınız \"$clan\" ($tag)';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Bağış oranınız $ratio. $donations birlik bağışladınız ve $received birlik aldınız.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Savaş tercihiniz $preference.';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return '$stars savaş yıldızınız var.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return '$trophies kupanız var. Şu anki liginiz $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Belediye Binası seviyeniz $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'İnşaatçı Binası seviyeniz $level ve $trophies kupanız var.';
  }

  @override
  String get gameBaseHome => 'Ana Üs';

  @override
  String get gameBaseBuilder => 'İnşaatçı Üssü';

  @override
  String get gameClanCapital => 'Klan Başkenti';

  @override
  String get gameTownHall => 'BB';

  @override
  String get gameTownHallLevel => 'BB Seviyesi';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Belediye Binası $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'BB $level';
  }

  @override
  String get gameExpLevel => 'Deneyim Seviyesi';

  @override
  String get gameTrophies => 'Kupalar';

  @override
  String get gameBuilderBaseTrophies => 'İÜ Kupaları';

  @override
  String get gameDonations => 'Bağışlar';

  @override
  String get gameDonationsReceived => 'Alınan Bağışlar';

  @override
  String get gameDonationsRatio => 'Bağış Oranı';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Seviye: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Kahramanlar';

  @override
  String get gameEquipment => 'Ekipmanlar';

  @override
  String get gameHeroesEquipments => 'Kahraman Ekipmanları';

  @override
  String get gameTroops => 'Birlikler';

  @override
  String get gameActiveSuperTroops => 'Aktif Süper Birlikler';

  @override
  String get gamePets => 'Evcil Hayvanlar';

  @override
  String get gameSiegeMachines => 'Kuşatma Makineleri';

  @override
  String get gameSpells => 'Büyüler';

  @override
  String get gameAchievements => 'Başarımlar';

  @override
  String get gameClanGames => 'Klan Oyunları';

  @override
  String get gameSeasonPass => 'Sezon Bileti';

  @override
  String get gameCreatorCode => 'İçerik Üretici Kodu: ClashKing';

  @override
  String get gameCreatorCodeDescription =>
      'Bilgi için dokunun • Bizi ücretsiz destekleyin!';

  @override
  String get gameCreatorCodeDialogTitle => 'ClashKing\'i destekleyin';

  @override
  String get gameCreatorCodeDialogDescription =>
      'Yaratıcı kodumuzu kullandığınızda, geliştirmeyi finanse etmeye yardımcı olur, uygulamayı ve botu herkes için ücretsiz tutar ve yeni özelliklerin eklenmesini desteklersiniz.\n\nOyun içi satın alımlarınızın %5\'ini size hiçbir ek ücret ödemeden alırız — herhangi bir Supercell oyununun mağazasına \"ClashKing\" yazmanız yeterlidir.\n\nDesteğiniz için teşekkür ederiz!';

  @override
  String get gameCreatorCodeDialogButton => 'Üretici Kodunu Kullan';

  @override
  String get clanTitle => 'Klan';

  @override
  String get clanSearchTitle => 'Klan ara';

  @override
  String get clanSearchPlaceholder => 'Klanın adı';

  @override
  String get clanNone => 'Klan yok';

  @override
  String get clanJoinToUnlock =>
      'Yeni özelliklerin kilidini açmak için bir klana katılın.';

  @override
  String get clanMembers => 'Üyeler';

  @override
  String get clanWarFrequency => 'Savaş sıklığı';

  @override
  String get clanMinimumMembers => 'Asgari Üye';

  @override
  String get clanMaximumMembers => 'Azami Üye';

  @override
  String get clanLocation => 'Konum';

  @override
  String get clanMinimumPoints => 'Minimum klan puanı';

  @override
  String get clanMinimumLevel => 'Minimum klan seviyesi';

  @override
  String get clanInviteOnly => 'Yalnızca Davet';

  @override
  String get clanOpened => 'Açıldı';

  @override
  String get clanClosed => 'Kapalı';

  @override
  String get clanRoleLeader => 'Lider';

  @override
  String get clanRoleCoLeader => 'Yardımcı Lider';

  @override
  String get clanRoleElder => 'Büyük';

  @override
  String get clanRoleMember => 'Üye';

  @override
  String get clanWarFrequencyAlways => 'Her zaman';

  @override
  String get clanWarFrequencyNever => 'Hiçbir zaman';

  @override
  String get clanWarFrequencyUnknown => 'Bilinmeyen';

  @override
  String get clanWarFrequencyOncePerWeek => '1/hafta';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'Haftada 1\'den fazla';

  @override
  String get clanWarFrequencyRarely => 'Nadiren';

  @override
  String get timeHourIndicator => 'sa';

  @override
  String timeDaysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String timeDayAgo(int day) {
    return '$day gün önce';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour saat önce';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours saat önce';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute dakika önce';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes dakika önce';
  }

  @override
  String get timeJustNow => 'Az Önce';

  @override
  String get timeEndedJustNow => 'Az önce bitti';

  @override
  String timeEndedMinutesAgo(int minutes) {
    return '$minutes dakika önce sona erdi';
  }

  @override
  String timeEndedHoursAgo(int hours) {
    return '$hours saat önce sona erdi';
  }

  @override
  String timeEndedDaysAgo(int days) {
    return '$days gün önce sona erdi';
  }

  @override
  String timeStartsIn(String time) {
    return 'Başlamasına: $time';
  }

  @override
  String timeStartsAt(String time) {
    return '$time\'de başlıyor';
  }

  @override
  String timeEndsIn(String time) {
    return 'Bitmesine: $time';
  }

  @override
  String timeEndsAt(String time) {
    return '$time\'de bitiyor';
  }

  @override
  String get legendsTitle => 'Veri yanlış mı?';

  @override
  String get legendsNotInLeague => 'Efsane ligde değil';

  @override
  String get legendsNoDataToday =>
      'Efsane Lig\'de değilsin ama geçmiş sezonlar mevcut.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Güne $trophies kupayla başladın.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Şu anda $trophies kupa ile $country sıralamasında yer almıyorsunuz.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Şu anda $rank ($country) sıralamasındasınız ve $trophies kupanız var.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Şu ana kadar $trophies kupa kazandınız.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Şu ana kadar $trophies kupa kaybettiniz.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Şu anda $trophies kupa ile küresel sıralamada yer almıyorsunuz.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'Şu anda dünya genelinde $trophies kupayla $rank. sıradasınız.';
  }

  @override
  String get legendsNoRank => 'Sıralama yok';

  @override
  String get legendsBestTrophies => 'En İyi Kupalar';

  @override
  String get legendsMostAttacks => 'En Çok Saldırı';

  @override
  String get legendsLastSeason => 'Geçen Sezon';

  @override
  String get legendsBestRank => 'En İyi Küresel Sıralama';

  @override
  String get legendsTrophiesBySeason => 'Sezonlara göre kupalar';

  @override
  String get legendsEosTrophies => 'Sezon Sonu Kupaları';

  @override
  String get legendsEosDetails => 'Sezon Sonu Detayları';

  @override
  String get legendsInaccurateTitle => 'Veri yanlış mı?';

  @override
  String get legendsInaccurateIntro =>
      'Clash of Clans API\'sinin sınırlamaları nedeniyle, verilerimiz her zaman mükemmel derecede doğru olmayabilir. İşte nedeni:';

  @override
  String get legendsInaccurateApiDelayTitle => '1. API Gecikmesi:';

  @override
  String get legendsInaccurateApiDelayBody =>
      'API\'nin güncellenmesi 5 dakikaya kadar sürebilir ve bu da gerçek zamanlı kupa değişikliklerinin yansıtılmasında gecikmeye neden olabilir.';

  @override
  String get legendsInaccurateConcurrentTitle => '2. Eş Zamanlı Değişiklikler:';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Çoklu Saldırılar/Savunmalar:';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Birden fazla saldırı veya savunma hızlı bir şekilde gerçekleşirse, API birleşik sonuçlar gösterebilir (örneğin, +68 veya -68).';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Eş Zamanlı Saldırı ve Savunma:';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Eğer saldırı ve savunma aynı anda gerçekleşirse, karışık bir sonuç görebilirsiniz (örneğin, +4).';

  @override
  String get legendsInaccurateNetGainTitle => '3. Net Kazanç/Kayıp:';

  @override
  String get legendsInaccurateNetGainBody =>
      'Zamanlama sorunlarına rağmen, günün genel net kazanç veya kaybı doğrudur.';

  @override
  String get legendsInaccurateConclusion =>
      'Bu sınırlamalar Clash of Clans API\'sini kullanan tüm araçlarda yaygındır. Ne yazık ki bunu düzeltemeyiz çünkü bu Supercell\'in elinde. Bu sınırlamaları telafi etmek ve gerçeğe olabildiğince yakın sonuçlar sağlamak için elimizden geleni yapıyoruz. Anlayışınız için teşekkür ederiz!';

  @override
  String get statsSeasonStats => 'Sezon İstatistikleri';

  @override
  String get statsByDay => 'Güne göre';

  @override
  String get statsBySeason => 'Sezona göre';

  @override
  String statsDayIndex(int index) {
    return 'Gün $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index günler';
  }

  @override
  String statsSeasonDate(String date) {
    return '$date sezon';
  }

  @override
  String get statsAllTownHalls => 'Tüm Belediye Binaları';

  @override
  String get statsMembers => 'Üye İstatistikleri';

  @override
  String get todoTitle => 'Yapılacaklar Listesi';

  @override
  String get todoExplanationTitle => 'Görev Hesaplaması';

  @override
  String get todoExplanationIntro =>
      'Görev tamamlanma yüzdesi, aşağıdaki faaliyetlerin belirli ağırlıklara göre hesaplanmasıyla hesaplanır:';

  @override
  String get todoExplanationLegendsTitle => 'Efsane Lig:';

  @override
  String get todoExplanationLegends =>
      'Hesap başına 8 puan ağırlığı, 1 saldırı = 1 puan.';

  @override
  String get todoExplanationRaidsTitle => 'Baskınlar:';

  @override
  String get todoExplanationRaids =>
      'Hesap başına 5 puan (veya son saldırı açılmışsa 6) ağırlığı, 1 saldırı = 1 puan.';

  @override
  String get todoExplanationClanWarsTitle => 'Klan Savaşları:';

  @override
  String get todoExplanationClanWars =>
      'Hesap başına 2 puan ağırlığı, 1 saldırı = 1 puan.';

  @override
  String get todoExplanationCwlTitle => 'Klan Savaş Ligi:';

  @override
  String get todoExplanationCwl =>
      'Hesap başına 1 puan ağırlığı, 1 saldırı = 1 puan. Oyuncu lig klanında değilse KSL takip edilemez.';

  @override
  String get todoExplanationPassAndGamesTitle =>
      'Sezon Bileti & Klan Oyunları:';

  @override
  String get todoExplanationPassAndGames =>
      'Hesap başına 2 puanlık ağırlık. Oran, kalan gün sayısına (Bilet için 1 ay ve klan oyunları için 6 gün) dayanmaktadır. Yeşil = Bileti veya oyunları tamamlama yolunda, kırmızı = programın gerisinde.';

  @override
  String get todoExplanationConclusion =>
      'Son yüzde, devam eden olaylar sırasında tamamlanan toplam eylemlerin toplam gerekli eylemlere bölünmesiyle hesaplanır. 14 günden uzun süredir etkin olmayan hesaplar hesaplamadan hariç tutulur.';

  @override
  String todoAccountsNumber(int number) {
    return '$number hesaplar';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number aktif hesaplar';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number inaktif hesaplar';
  }

  @override
  String get todoAccountsActive => 'Aktif hesaplar';

  @override
  String get todoAccountsInactive => 'İnaktif hesaplar';

  @override
  String get todoAccountsNoInactive => 'İnaktif hesap yok.';

  @override
  String get todoAccountsNoActive => 'Aktif hesap yok.';

  @override
  String todoAttacksLeftDescription(int attacks, String type) {
    return '$attacks saldırı hakkınız kaldı ($type).';
  }

  @override
  String todoDefensesLeftDescription(int defenses, String type) {
    return '$defenses savunmanız kaldı ($type).';
  }

  @override
  String todoNoAttacksLeftDescription(String type) {
    return 'Tebrikler, tüm saldırılarınızı ($type) gerçekleştirdiniz!';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'Etkinliğin ($type) sonuna yetişmek için bugün $points puanınız kaldı.';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Tebrikler, etkinliğin sonunda maksimum ödülü almaya hak kazandınız ($type)!';
  }

  @override
  String get warTitle => 'Savaş';

  @override
  String get warFrequency => 'Savaş sıklığı';

  @override
  String get warParticipation => 'Savaş Katılımı';

  @override
  String get warLeague => 'Savaş/Lig';

  @override
  String get warHistory => 'Savaş Geçmişi';

  @override
  String get warLog => 'Savaş Günlüğü';

  @override
  String warLogClosed(String clan) {
    return 'Savaş günlüğü kapatıldı.';
  }

  @override
  String get warStats => 'Savaş İstatistikleri';

  @override
  String get warOngoing => 'Devam eden savaş';

  @override
  String warIsNotInWar(String clan) {
    return '$clan savaşta değil.';
  }

  @override
  String get warAskForWar =>
      'Savaş başlatmak için lidere veya yardımcı lidere başvurun.';

  @override
  String get warAskForWarLogOpening =>
      'Savaş günlüğünü açmak için bir lidere veya yardımcı lidere başvurun.';

  @override
  String get warEnded => 'Savaş sonu';

  @override
  String get warPreparation => 'Hazırlık';

  @override
  String get warPerfectWar => 'Mükemmel savaş';

  @override
  String get warVictory => 'Zafer';

  @override
  String get warDefeat => 'Yenilgi';

  @override
  String get warDraw => 'Berabere';

  @override
  String get warTeamSize => 'Takım boyutu';

  @override
  String get warMyTeam => 'Takımım';

  @override
  String get warEnemiesTeam => 'Düşman';

  @override
  String get warClanDraw => 'İki klan da berabere';

  @override
  String get warStateOfTheWar => 'Savaş durumu';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan takımının liderliği ele geçirebilmesi için hala $star yıldıza veya $stars2 yıldıza ve %$percent\'e ihtiyacı var.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan \'ın liderliği ele geçirmek için hala %$percent veya 1 yıldıza daha ihtiyacı var';
  }

  @override
  String get warNoDataAvailableForThisWar => 'Bu savaş için veri mevcut değil';

  @override
  String get warCalculatorFast => 'Hızlı hesaplayıcı';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return '%$percentNeeded oranında bir yıkım oranına ulaşmak için toplamda %$result gerekiyor.';
  }

  @override
  String get warCalculatorNeededOverall => '% Genel olarak ihtiyaç duyuluyor';

  @override
  String get warCalculatorCalculate => 'Hesapla';

  @override
  String get warAttacksTitle => 'Saldırılar';

  @override
  String get warAttacksNone => 'Henüz saldırı yok';

  @override
  String get warAttacksBest => 'En iyi saldırılar';

  @override
  String get warAttacksCount => 'Saldırı Sayısı';

  @override
  String get warAttacksMissed => 'Kaçırılan Saldırılar';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'Son $number_war savaşta $number_time kez saldırdın.';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'Savaş başına ortalama $stars yıldızınız vardı.';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'Savaş başına ortalama %$percent yıkım oranınız vardı.';
  }

  @override
  String get warDefensesTitle => 'Savunmalar';

  @override
  String get warDefensesNone => 'Henüz savunma yok';

  @override
  String get warDefensesBest => 'En iyi savunmalar';

  @override
  String warDefensesBestOutOf(int number) {
    return 'En iyi savunma ($number arasından)';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'Son $number_war savaşta $number_time kez savundun.';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'Savunma başına ortalama $stars yıldızınız vardı.';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'Savunma başına ortalama %$percent yıkım oranınız vardı.';
  }

  @override
  String get warStarsTitle => 'Yıldızlar';

  @override
  String get warStarsAverage => 'Ortalama Yıldızlar';

  @override
  String get warStarsNumber => 'Yıldız Sayısı';

  @override
  String get warStarsOne => '1 yıldız';

  @override
  String get warStarsTwo => '2 yıldız';

  @override
  String get warStarsThree => '3 yıldız';

  @override
  String get warStarsZero => '0 Yıldız';

  @override
  String get warStarsBestPerformance => 'En İyi Performans';

  @override
  String get warDestructionTitle => 'Yıkım';

  @override
  String get warDestructionAverage => 'Ortalama Yıkım';

  @override
  String get warDestructionRate => 'Yıkım oranı';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Klanınız son 50 savaşta $wins savaş (%$percent) kazandı.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Klanınız son 50 savaşta $losses savaş (%$percent) kaybetti.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Klanınız son 50 savaşta $draws savaş (%$percent) berabere kaldı.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Klanınızda son 50 savaşta ortalama $members üye yer aldı.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Klanınız son 50 savaşta savaş başına ortalama $stars yıldıza sahipti. Toplam yıldızların $percent\'ini temsil ediyor.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Klanınızın son 50 savaşta ortalama %$percent yıkım oranı vardı.';
  }

  @override
  String get warPositionMap => 'Harita Pozisyonu';

  @override
  String get warPositionAbbr => 'Sıra';

  @override
  String get warPositionOrder => 'Sıralama';

  @override
  String get warOpponentTownhall => 'Karşı KB';

  @override
  String get warOpponentLowerTownhall => 'Alt KB';

  @override
  String get warOpponentUpperTownhall => 'Üst KB';

  @override
  String get warOpponentEqualThLevel => 'Eşit BB';

  @override
  String get warOpponentSelectMembersThLevel => 'Üyelerin BB Seviyesi';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Rakiplerin BB Seviyesi';

  @override
  String warFiltersLastXwars(int number) {
    return 'Son $number savaş';
  }

  @override
  String get warFiltersFriendly => 'Arkadaş canlısı';

  @override
  String get warFiltersRandom => 'Rastgele';

  @override
  String get warVisibilityToggleTownHall =>
      'Eski BB seviyelerindeki istatistikleri gizle/göster';

  @override
  String get warEventsTitle => 'Etkinlikler';

  @override
  String get warEventsNewest => 'En yeni';

  @override
  String get warEventsOldest => 'En eski';

  @override
  String get warStatusReady => 'Katılıyor';

  @override
  String get warStatusUnready => 'Katılmıyor';

  @override
  String get warStatusMissed => 'Kaçırıldı';

  @override
  String get warAbbreviationAvg => 'Ort';

  @override
  String get warAbbreviationAvgPercentage => 'Ort %';

  @override
  String get cwlTitle => 'KSL';

  @override
  String get cwlClanWarLeague => 'Klan Savaş Ligi';

  @override
  String get cwlOngoing => 'Devam eden KSL';

  @override
  String get cwlRounds => 'Turlar';

  @override
  String cwlRoundNumber(int number) {
    return 'Tur $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Şu anda tur $round.';
  }

  @override
  String cwlRank(int rank) {
    return 'Klanınız şu anda $rank sıralamasında.';
  }

  @override
  String cwlStars(int stars) {
    return 'Klanınızın toplam $stars yıldızı var.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Klanınızın toplam yıkım oranı %$percent\'dir.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Klanınızın toplam $totalAttacks olası saldırıdan $attacks tanesine sahiptir.';
  }

  @override
  String get joinLeaveTitle => 'Katılma/Ayrılma Günlükleri (Mevcut Sezon)';

  @override
  String get joinLeaveJoin => 'Katıl';

  @override
  String get joinLeaveLeave => 'Ayrıl';

  @override
  String get joinLeaveReset => 'Sıfırla';

  @override
  String get joinLeaveJoins => 'Katılmalar';

  @override
  String get joinLeaveLeaves => 'Ayrılmalar';

  @override
  String get joinLeaveUniquePlayers => 'Benzersiz Oyuncular';

  @override
  String get joinLeaveMovingPlayers => 'Hareketli Oyuncular';

  @override
  String get joinLeaveMostMovingPlayers => 'En Çok Hareket Eden Oyuncular';

  @override
  String get joinLeaveStillInClan => 'Hala Klanda';

  @override
  String get joinLeaveLeftForever => 'Tamamen Ayrıldı';

  @override
  String get joinLeaveRejoinedPlayers => 'Yeniden Katılan Oyuncular';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Ortalama Katılma/Ayrılma Süresi';

  @override
  String get joinLeavePeakHour => 'En Aktif Saat';

  @override
  String joinLeaveNumberDescription(int number, String date) {
    return 'Mevcut sezonda ($date) $number adet ayrılma etkinliği gerçekleşti.';
  }

  @override
  String joinLeaveJoinNumberDescription(int number, String date) {
    return 'Mevcut sezonda ($date) $number adet katılım etkinliği gerçekleşti.';
  }

  @override
  String joinLeaveMovingNumberDescription(int number, String date) {
    return 'Mevcut sezonda ($date) $number oyuncu klandan ayrıldı ve yeniden katıldı.';
  }

  @override
  String joinLeaveUniqueNumberDescription(int number, String date) {
    return 'Mevcut sezonda ($date) $number benzersiz oyuncu klana katıldı/klandan ayrıldı.';
  }

  @override
  String joinLeaveStillInClanNumberDescription(int number) {
    return '$number oyuncu klana katıldı ve hala klanda.';
  }

  @override
  String joinLeaveLeftClanNumberDescription(int number) {
    return '$number oyuncu klana katıldı, sonra ayrıldı ve bir daha asla katılmadı';
  }

  @override
  String joinLeaveLeftOnAt(String date, String time) {
    return '$date tarihinde ${time}te ayrıldı.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return '$date tarihinde ${time}te katıldı.';
  }

  @override
  String get raidsTitle => 'Baskınlar';

  @override
  String get raidsLast => 'Son baskınlar';

  @override
  String get raidsOngoing => 'Devam eden baskınlar';

  @override
  String get raidsDistrictsDestroyed => 'Yıkılan bölgeler';

  @override
  String get raidsCompleted => 'Tamamlanan baskınlar';

  @override
  String get searchNoResult => 'Sonuç yok.';

  @override
  String get maintenanceTitle => 'Bakım';

  @override
  String get maintenanceDescription =>
      'Clash of Clans şu anda bakımda olduğundan API\'ye erişemiyoruz. Lütfen daha sonra tekrar kontrol edin.';

  @override
  String get downloadTooltip => 'KSL özetini indirin';

  @override
  String get downloadInProgress =>
      'Dosya indiriliyor... Birkaç saniye sürebilir...';

  @override
  String downloadSuccess(String path) {
    return 'Dosya $path konumuna başarıyla kaydedildi';
  }

  @override
  String get downloadError => 'Dosya indirilemedi';

  @override
  String get dashboardTitle => 'Kontrol Paneli';

  @override
  String get toolsTitle => 'Araçlar';

  @override
  String get navigationTeam => 'Takımlar';

  @override
  String get navigationStatistics => 'İstatistikler';

  @override
  String get versionDevice => 'Sürüm & Cihaz';

  @override
  String get settingsLicenses => 'Açık Kaynak Lisansları';

  @override
  String get settingsLicensesSubtitle =>
      'Üçüncü-parti kütüphaneler için lisansları görüntüleyin';

  @override
  String get settingsPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get settingsPrivacyPolicySubtitle => 'Verilerinizi nasıl işliyoruz?';

  @override
  String get betaFeature => 'Beta Özellikleri';

  @override
  String get betaLabel => 'Beta';

  @override
  String get betaDescription =>
      'Bu özellik şu anda beta aşamasındadır, bazı hatalar içerebilir veya eksik olabilir. İyileştirmeler üzerinde aktif olarak çalışıyoruz ve geri bildirimlerinizi bekliyoruz. Lütfen fikirlerinizi paylaşın ve Discord Sunucumuzdaki sorunları bildirin, böylece daha iyi hale getirmemize yardımcı olun.';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsSelectLanguage => 'Bir dil seçin';

  @override
  String get settingsToggleTheme => 'Temayı Değiştir';

  @override
  String get faqTitle => 'S.S.S';

  @override
  String get faqSubtitle => 'Sıkça Sorulan Sorular';

  @override
  String get faqIsThisFromSupercell => 'Bu uygulama Supercell\'e mi ait?';

  @override
  String get faqFanContentPolicy =>
      'Bu materyal resmi değildir ve Supercell tarafından desteklenmemektedir. Daha fazla bilgi için Supercell\'in Hayran İçerik Politikasına bakın: www.supercell.com/fan-content-policy.';

  @override
  String get faqWhyNotAccurate =>
      'Veriler bazen neden yanlış veya eksik oluyor?';

  @override
  String get faqClanNotTracked => 'Klan izlenmiyor';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing bu bilgiyi yalnızca klan izleniyorsa alabilir. Klanınız izlenmemişse lütfen ClashKing Bot\'unu Discord Sunucunuza davet edin ve /addclan komutunu kullanın. Bu özelliği yakında uygulamada kullanılabilir hale getirmek için çalışıyoruz.';

  @override
  String get faqTrackingDown => 'Takip etmek';

  @override
  String get faqTrackingDownAnswer =>
      'İzleme belirli bir süre boyunca çalışmayı durdurabilir. Bu nedenle bazen verilerinizde boşluklar olabilir. Bunu iyileştirmek için çalışıyoruz.';

  @override
  String get faqApiLimitation => 'Clash of Clans API sınırlaması';

  @override
  String get faqApiLimitationAnswer =>
      'Bazı veriler Clash of Clans tarafından sağlanır ve API\'lerinin bazı sınırlamaları vardır. Bu, efsanelerin takibi için geçerlidir, bazen tek bir saldırıymış gibi kupa kazanımını ve kaybını üst üste koyar. Bu ayrıca bina seviyeleriniz hakkında hiçbir bilgiye sahip olmamamızın nedenidir.';

  @override
  String get faqSupportWork => 'Çalışmalarınıza nasıl destek olabilirim?';

  @override
  String get faqSupportWorkAnswer => 'Bizi desteklemenin birkaç yolu var:';

  @override
  String get faqUseCodeClashKing => '\"ClashKing\" kodunu kullanın';

  @override
  String get faqSupportUsOnPatreon => 'Bizi Patreon’da Destekleyin';

  @override
  String get faqShareTheApp => 'Uygulamayı arkadaşlarınızla paylaşın';

  @override
  String get faqRateTheApp => 'Uygulamayı mağazada derecelendirin';

  @override
  String get faqHelpUsTranslate => 'Uygulamayı çevirmemize yardım edin';

  @override
  String get faqHowToInviteTheBot =>
      'Botunuzu Discord Sunucuma nasıl davet edebilirim?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Aşağıdaki butona tıklayarak botumuzu sunucunuza davet edebilirsiniz. Botu eklemek için \"Sunucuyu Yönet\" iznine ihtiyacınız olacak.';

  @override
  String get faqInviteTheBot => 'ClashKing Botunu Davet Et';

  @override
  String get faqNeedHelp =>
      'Yardıma ihtiyacım var veya bir öneride bulunmak istiyorum. Sizinle nasıl iletişime geçebilirim?';

  @override
  String get faqNeedHelpAnswer =>
      'Yardım istemek veya geri bildirim sağlamak için Discord Sunucumuza katılabilir veya devs@clashk.ing adresine e-posta gönderebilirsiniz. Lütfen yalnızca İngilizce veya Fransızca yazın.';

  @override
  String get faqSendEmail => 'E-posta gönderin';

  @override
  String get faqJoinDiscord => 'Discord Sunucumuza Katılın';

  @override
  String get faqCannotOpenMailClient =>
      'Bazı nedenlerden dolayı posta istemcinizi açamadık. E-posta adresini sizin için kopyaladık. Bir e-posta yazıp adresi alıcı alanına yapıştırabilirsiniz.';

  @override
  String get translationHelpUsTranslate => 'Çeviriye yardımcı olun';

  @override
  String get translationSuggestFeatures => 'Özellik önerin';

  @override
  String get translationThankYou => 'Teşekkürler!';

  @override
  String get translationThankYouContent =>
      'Bu uygulamayı dünya çapında daha fazla insana ulaştırmamıza yardımcı olan tüm harika çevirmenlerimize çok teşekkür ederiz!';

  @override
  String get translationHelpTranslateContent =>
      'Uygulamayı Crowdin\'de çevirmemize yardımcı olabilirsiniz. Diliniz Crowdin\'de mevcut değilse, Discord Sunucumuzda talep etmekten çekinmeyin. Yardımınız için çok teşekkür ederim!';

  @override
  String get translationHelpTranslateButton =>
      'Crowdin\'de Çeviriye Yardım Edin';

  @override
  String get translationCurrentTranslators => 'Güncel Tercümanlar';
}
