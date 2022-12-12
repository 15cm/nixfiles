case $1 in
    pre)
      for mod in psmouse ath11k_pci; do
            rmmod $mod
        done
    ;;
    post)
      for mod in psmouse ath11k_pci; do
            modprobe $mod
        done
    ;;
esac
