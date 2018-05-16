# otus
# Спасибо Леониду за подсказки! :)
# Задание

Работа с LVM
на имеющемся образе
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /

уменьшить том под / до 8G
выделить том под /home
выделить том под /var
/var - сделать в mirror
/home - сделать том для снэпшотов
прописать монтирование в fstab
попробовать с разными опциями и разными файловыми системами ( на выбор)
- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановится со снэпшота
- залоггировать работу можно с помощью утилиты screen

* на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt

# уменьшить том под / до 8G

```
# создаем раздел для бекапа рута
sudo pvcreate /dev/sdb
sudo vgcreate VGBackUpRoot /dev/sdb
sudo lvcreate -n LVBackUpRoot -l +100%FREE /dev/VGBackUpRoot
sudo mkfs.xfs /dev/VGBackUpRoot/LVBackUpRoot
sudo mount /dev/VGBackUpRoot/LVBackUpRoot /mnt
# создаем и разворачиваем бекап рута в новый раздел
sudo yum install xfsdump -y
sudo xfsdump -f /tmp/root.dump /dev/VolGroup00/LogVol00
sudo xfsrestore -f /tmp/root.dump /mnt/
# готовим grub
sudo mount --bind /proc/ /mnt/proc/ && sudo mount --bind /sys/ /mnt/sys/ && sudo mount --bind /dev/ /mnt/dev/ && sudo mount --bind /run/ /mnt/run/ && sudo mount --bind /boot/ /mnt/boot/
sudo chroot /mnt/
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
В /boot/grub2/grub.cfg меняем rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=VGBackUpRoot/LVBackUpRoot и загружаемся с рутом на LVBackUpRoot

```
# Удаляем старый том и создаем новый на 8гб
sudo lvremove /dev/VolGroup00/LogVol00
sudo lvcreate -n LogVol00 -L 8G /dev/VolGroup00
sudo mkfs.xfs /dev/VolGroup00/LogVol00
sudo mount /dev/VolGroup00/LogVol00 /mnt
# После этого делаем\загружаем дамп, монтируем диски, запускаем граб мкконфиг
```

# выделить том под /var, /var - сделать в mirror 

```
# Создаем VL зеркало
sudo pvcreate /dev/sdc /dev/sdd
sudo vgcreate VolGroupVar /dev/sdc /dev/sdd
sudo lvcreate -L 1G -m1 -n LogVolVar VolGroupVar
sudo mkfs.xfs /dev/VolGroupVar/LogVolVar
sudo mount /dev/VolGroupVar/LogVolVar /mnt
sudo cp -aR /var/* /mnt/
sudo rm -rf /var/*
sudo umount /mnt
mount /dev/VolGroupVar/LogVolVar /var
```
файл /etc/fstab добавляем строку "/dev/mapper/VolGroupVar-LogVolVar /var                       xfs     defaults        0 0" для автоматического монтирования

#Доделываем задачу "уменьшить том под / до 8G"

```
# Перезагружаемся чтобы загрузиться с рута на 8гиговом разделе и удаляем ненужную теперь VG для дампа
sudo lvremove /dev/VGBackUpRoot/LVBackUpRoot
sudo vgremove /dev/VGBackUpRoot
```

# выделить том под /home

```
# Создаем LV для Home 5гигов
sudo lvcreate -n VLHome -L 5G /dev/VolGroup00
sudo mkfs.xfs /dev/VolGroup00/VLHome
# Монитруем новый в mnt, копируем на него данные со старого Home, очищаем старый Home и монтируем новый в Home
sudo mount /dev/VolGroup00/VLHome /mnt/
sudo cp -aR /home/* /mnt/
sudo rm -rf /home/*
sudo umount /mnt/
sudo mount /dev/VolGroup00/VLHome /home/
```
В файл /etc/fstab добавляем строку "/dev/mapper/VolGroup00-VLHome /home                       xfs     defaults        0 0" для автоматического монтирования



# home - сделать том для снэпшотов

```
sudo touch /home/file{1..100}
sudo lvcreate -L 5GB -s -n VLHomeSnap /dev/VolGroup00/VLHome
sudo rm /home/file{50..100}
sudo cd / 
umount /home
lvconvert --merge /dev/VolGroup00/VLHomeSnap
mount /home
```