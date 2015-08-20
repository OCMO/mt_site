#======== URL / PATH =================
AdminScript          admin
AdminCGIPath         /mt/
CGIPath              /mt/
StaticWebPath        /mt-static/

#======== DATABASE SETTINGS ==========
ObjectDriver         DBI::mysql
Database             movabletype
DBUser               sixapart
DBPassword           p@ssw0rd
DBHost               localhost
DBSocket             /data/database/mysql/mysql.sock

#======== MISC SETTINGS =============
PIDFilePath /app/run/movabletype.pid

DefaultLanguage      en_us
DefaultTimezone      0

BaseSitePath         /data/file/static

TransparentProxyIPs  1

YAMLModule           YAML::Syck

DBUmask              0022
HTMLUmask            0022
UploadUmask          0022
DirUmask             0022