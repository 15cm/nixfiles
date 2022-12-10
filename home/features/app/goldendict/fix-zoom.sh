config_file=$HOME/.config/goldendict/config
if [ -f $config_file ];then
  sed 's|<zoomFactor>.*</zoomFactor>|<zoomFactor>3</zoomFactor>|g' -i $config_file
fi
