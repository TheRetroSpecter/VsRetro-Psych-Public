function onCreate()
	local lSongName = string.lower(songName):gsub(" ", "-")

	setProperty("hasGhostSprite", true)
	setProperty("shouldShake", true)
	if lSongName == "ectospasm" then
		setProperty("windowShakeAmount", 5)
	elseif lSongName == "spectral" then
		setProperty("windowShakeAmount", 3)
	end

	close(true)
end