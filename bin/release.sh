#!/bin/bash

RELEASE="${1}"
DATESTAMP="${2}"

RELEASE_DIRECTORY="/cygdrive/c/CYGWIN_RELEASES/${RELEASE}/${DATESTAMP}"

SOURCE_UPSTREAM="../Upstream/Altis-4.4r2/Altis-4.4r2"
SOURCE_TREE="../Altis"
SOURCE_MISSION="../Mission"
SOURCE_TEXTURES="../Textures"

PBO_CONSOLE="/cygdrive/c/Program Files/PBO Manager v.1.4 beta/PBOConsole.exe"

echo "building a release for ${RELEASE} (${DATESTAMP})"

for DIRECTORY in "Altis_Life.Altis" "life_server"; do
  mkdir -pv "${RELEASE_DIRECTORY}/${DIRECTORY}"

  #
  # preseed the directory with upstream files
  #
  rsync -Pavpx --delete \
    "${SOURCE_UPSTREAM}/${DIRECTORY}/." \
    "${RELEASE_DIRECTORY}/${DIRECTORY}/."
done

#
# copy the mission file
#
test -f "${SOURCE_MISSION}/mission.sqm" && rsync -Pavpx \
  "${SOURCE_MISSION}/mission.sqm" \
  "${RELEASE_DIRECTORY}/Altis_Life.Altis/."

#
# copy the textures
#
test -d "${SOURCE_TEXTURES}/textures" && rsync -Pavpx \
  "${SOURCE_TEXTURES}/textures/." \
  "${RELEASE_DIRECTORY}/Altis_Life.Altis/textures/."

for DIRECTORY in "Altis_Life.Altis" "life_server"; do
  #
  # copy our overlay files into the release
  #
  test -d "${SOURCE_TREE}/${DIRECTORY}" && rsync -Pavpx \
    "${SOURCE_TREE}/${DIRECTORY}/." \
    "${RELEASE_DIRECTORY}/${DIRECTORY}/."
	
  #
  # build the PBO files
  #
  "${PBO_CONSOLE}" \
    -pack "C:\\CYGWIN_RELEASES\\${RELEASE}\\${DATESTAMP}\\${DIRECTORY}" \
          "C:\\CYGWIN_RELEASES\\${RELEASE}\\${DATESTAMP}\\${DIRECTORY}.pbo"

  if [[ "production" == "${RELEASE}" ]]; then
      mkdir -pv "production/${DATESTAMP}"
      rsync -Pavpx \
        "${RELEASE_DIRECTORY}/${DIRECTORY}.pbo" \
        "production/${DATESTAMP}/${DIRECTORY}.pbo"
    fi

done

SERVER="127.0.0.1"

if [[ "testing" == "${RELEASE}" ]]; then
  SERVER="192.168.4.114"
fi

if [[ "production" == "${RELEASE}" ]]; then
  SERVER="altisliferpg.xoreaxeax.de"
fi

#
# deploy to server
#
TARGET_DIRECTORY="/home/steam/Steam/steamapps/common/Arma\ 3\ Server"

rsync -Pavpx \
    "${RELEASE_DIRECTORY}/Altis_Life.Altis.pbo" \
      "steam@${SERVER}:${TARGET_DIRECTORY}/mpmissions/."

rsync -Pavpx \
          "${RELEASE_DIRECTORY}/life_server.pbo" \
                  "steam@${SERVER}:${TARGET_DIRECTORY}/@life_server/addons/."

#
# restart arma3 on betaserver
#
if [[ "testing" == "${RELEASE}" ]]; then
  ssh steam@${SERVER} -t make -C /home/steam restart
fi

sleep 1

#
# validate the contents so we know we copied everything correctly :)
#
ls -ali "${RELEASE_DIRECTORY}"

echo

sha1sum ${RELEASE_DIRECTORY}/Altis_Life.Altis.pbo
ls -al ${RELEASE_DIRECTORY}/Altis_Life.Altis.pbo
ssh -q steam@altisliferpg.xoreaxeax.de -t sha1sum "${TARGET_DIRECTORY}/mpmissions/Altis_Life.Altis.pbo"
ssh -q steam@altisliferpg.xoreaxeax.de -t ls -al "${TARGET_DIRECTORY}/mpmissions/Altis_Life.Altis.pbo"

echo

sha1sum ${RELEASE_DIRECTORY}/life_server.pbo
ls -al ${RELEASE_DIRECTORY}/life_server.pbo
ssh -q steam@altisliferpg.xoreaxeax.de -t sha1sum "${TARGET_DIRECTORY}/@life_server/addons/life_server.pbo"
ssh -q steam@altisliferpg.xoreaxeax.de -t ls -al "${TARGET_DIRECTORY}/@life_server/addons/life_server.pbo"

exit 0

