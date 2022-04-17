## Репозиторий с личными скриптами для упрощения некотрых робочих процесов.  

- [WoL Enable Service](https://github.com/dima101097/linux/tree/main/WoL_Enable) - Служба автоматического включения WoL в linux после запуска. 
```sh
    Сохранить WoL_Enable.sh в удобном месте, заменил название интерфейса.
    Создать, либо сохратить wol_enable.service по пути /lib/systemd/system/ и указать полный путь к sh скрипту.
    Выполинь команду sudo systemctl enable wol_enable.service 
 ```   
