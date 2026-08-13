param(
    [string]$Ffmpeg = ''
)

$ErrorActionPreference = 'Stop'

$items = @(
    @{
        Title = 'File:Single Cow Moo.ogg'
        Name = 'vaca.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/a/a5/Single_Cow_Moo.ogg/Single_Cow_Moo.ogg.mp3'
    },
    @{
        Title = 'File:Wiehern.ogg'
        Name = 'caballo.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/d/db/Wiehern.ogg/Wiehern.ogg.mp3'
    },
    @{
        Title = 'File:Mudchute pig 1.ogg'
        Name = 'cerdo.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/7/73/Mudchute_pig_1.ogg/Mudchute_pig_1.ogg.mp3'
    },
    @{
        Title = 'File:Sheep bleat.ogg'
        Name = 'oveja.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/2/28/Sheep_bleat.ogg/Sheep_bleat.ogg.mp3'
    },
    @{
        Title = 'File:Herd of goats bleating.ogg'
        Name = 'cabra.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/b/bc/Herd_of_goats_bleating.ogg/Herd_of_goats_bleating.ogg.mp3'
    },
    @{
        Title = 'File:157763 felix-blume a-donkey-is-braying-in-his-enclosure-in-south-of-france.wav'
        Name = 'burro.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/2/25/157763_felix-blume_a-donkey-is-braying-in-his-enclosure-in-south-of-france.wav/157763_felix-blume_a-donkey-is-braying-in-his-enclosure-in-south-of-france.wav.mp3'
    },
    @{
        Title = 'File:Chickens demanding food.ogg'
        Name = 'gallina.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/d/d6/Chickens_demanding_food.ogg/Chickens_demanding_food.ogg.mp3'
    },
    @{
        Title = 'File:Pekin duck & mallard.ogg'
        Name = 'pato.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/3/39/Pekin_duck_%26_mallard.ogg/Pekin_duck_%26_mallard.ogg.mp3'
    },
    @{
        Title = 'File:Barking of a dog.ogg'
        Name = 'perro.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/a/a2/Barking_of_a_dog.ogg/Barking_of_a_dog.ogg.mp3'
    },
    @{
        Title = 'File:Meow of a Siamese cat - freemaster2.wav'
        Name = 'gato.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/8/81/Meow_of_a_Siamese_cat_-_freemaster2.wav/Meow_of_a_Siamese_cat_-_freemaster2.wav.mp3'
    },
    @{
        Title = 'File:Rabbit oinks and squeaks.wav'
        Name = 'conejo.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/4/49/Rabbit_oinks_and_squeaks.wav/Rabbit_oinks_and_squeaks.wav.mp3'
    },
    @{
        Title = 'File:Parrots perroquets.ogg'
        Name = 'loro.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/9/9e/Parrots_perroquets.ogg/Parrots_perroquets.ogg.mp3'
    },
    @{
        Title = 'File:Lion raring-sound1TamilNadu178.ogg'
        Name = 'leon.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/7/7d/Lion_raring-sound1TamilNadu178.ogg/Lion_raring-sound1TamilNadu178.ogg.mp3'
    },
    @{
        Title = 'File:Elephant voice - trumpeting.ogg'
        Name = 'elefante.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/4/40/Elephant_voice_-_trumpeting.ogg/Elephant_voice_-_trumpeting.ogg.mp3'
    },
    @{
        Title = 'File:Giraffe Hum.oga'
        Name = 'jirafa.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/a/a8/Giraffe_Hum.oga/Giraffe_Hum.oga.mp3'
    },
    @{
        Title = 'File:Gr' + [char]0x00E9 + 'vys zebra (Sound Effects).ogg'
        Name = 'cebra.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/8/8a/Gr%C3%A9vys_zebra_%28Sound_Effects%29.ogg/Gr%C3%A9vys_zebra_%28Sound_Effects%29.ogg.mp3'
    },
    @{
        Title = 'File:Brown woolly monkey alarm call.wav'
        Name = 'mono.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/1/16/Brown_woolly_monkey_alarm_call.wav/Brown_woolly_monkey_alarm_call.wav.mp3'
    },
    @{
        Title = 'File:Giant panda twittering.ogg'
        Name = 'panda.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/b/b8/Giant_panda_twittering.ogg/Giant_panda_twittering.ogg.mp3'
    },
    @{
        Title = 'File:Yellowstone sound library - Grizzly Bear vocalizations - 001.mp3'
        Name = 'oso.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/4/41/Yellowstone_sound_library_-_Grizzly_Bear_vocalizations_-_001.mp3'
    },
    @{
        Title = 'File:Little Penguin (Eudyptula minor).ogg'
        Name = 'pinguino.mp3'
        Source = 'https://upload.wikimedia.org/wikipedia/commons/transcoded/2/2c/Little_Penguin_%28Eudyptula_minor%29.ogg/Little_Penguin_%28Eudyptula_minor%29.ogg.mp3'
    }
)

if (-not $Ffmpeg) {
    $Ffmpeg = python -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())'
}
if (-not (Test-Path -LiteralPath $Ffmpeg -PathType Leaf)) {
    throw 'No se encuentra ffmpeg. Pasa su ruta con -Ffmpeg.'
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$target = Join-Path $repositoryRoot 'assets\sonidos\animales'
New-Item -ItemType Directory -Path $target -Force | Out-Null

foreach ($item in $items) {
    $output = Join-Path $target $item.Name
    if (Test-Path -LiteralPath $output -PathType Leaf) {
        Write-Output "$($item.Name): ya existe"
        continue
    }

    $temporaryFile = [IO.Path]::GetTempFileName()
    try {
        curl.exe `
            -4 --fail --silent --show-error --location `
            --retry 2 --retry-all-errors --retry-delay 2 `
            --user-agent 'LaGranjaDeMichi/1.0' `
            --output $temporaryFile `
            $item.Source
        if ($LASTEXITCODE -ne 0) {
            throw "No se pudo descargar $($item.Title)."
        }
        & $Ffmpeg `
            -hide_banner -loglevel error -y `
            -i $temporaryFile `
            -t 4 -vn -ac 1 -ar 22050 -b:a 64k `
            -af 'loudnorm=I=-16:LRA=7:TP=-1.5' `
            $output
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg no pudo procesar $($item.Title)."
        }
        Write-Output "$($item.Name): $((Get-Item $output).Length) bytes"
        Start-Sleep -Milliseconds 750
    }
    finally {
        Remove-Item -LiteralPath $temporaryFile -Force
    }
}
