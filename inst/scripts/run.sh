#!/usr/bin/env sh

wModDir=$(dirname "$0")
export RUBYLIB=$RUBYLIB:$wModDir

while [ "$1" != "" ]; do
  case $1 in
    -s | --maxModSize)
      shift
      maxModSize=$1
      ;;
    -i | --infile)
      shift
      infile=$1
      ;;
    -w | --threshold)
      shift
      winThresh=$1
      ;;
    -m | --minFreq)
      shift
      minFreq=$1
      ;;
    -d | --outdir)
      shift
      outdir=$1
      ;;
    -o | --outfile1)
      shift
      outfile1=$1
      ;;
    -p | --outfile2)
      shift
      outfile2=$1
      ;;
    -g | --genes)
      shift
      genes=$1
      ;;
    -t | --sigThresh)
      shift
      sigThresh=$1
      ;;
    -b | --bgrate)
      shift
      bgrate=$1
      ;;
    -q | --quiet)
      verbose="false"
      ;;
  esac
  shift
done

if [ "$verbose" != "false" ]; then
  echo "infile:     $infile"
  echo "outdir:     $outdir"
  echo "outfile1:   $outfile1"
  echo "outfile2:   $outfile2"
  echo "maxModSize: $maxModSize"
  echo "threshold:  $winThresh"
  echo "minFreq:    $minFreq"
  echo "bgrate:     $bgrate"
  echo "winThresh:  $winThresh"
  echo "Generating Network..."
fi

# run winnow to generate exclusivity scores
ruby "$wModDir"/xorWinnow.rb "$infile" "$minFreq" "$winThresh" \
  >"$outdir"/network.dat

#search the network for RME modules
if [ "$verbose" != "false" ]; then
  echo "Searching the Network..."
  ruby "$wModDir"/depthOneSearch.rb "$infile" "$outdir"/network.dat 2 \
    "$maxModSize" "$genes" "$minFreq" "$bgrate" \
    | sort -nrk 1 \
    >"$outdir"/"$outfile1"
else
  ruby "$wModDir"/depthOneSearch.rb "$infile" "$outdir"/network.dat 2 \
    "$maxModSize" "$genes" "$minFreq" "$bgrate" false \
    | sort -nrk 1 \
    >"$outdir"/"$outfile1"
fi

# filter the potential modules and keep the largest/best scoring ones
ruby "$wModDir"/pickModules.rb "$outdir"/"$outfile1" "$infile" "$sigThresh" \
  >"$outdir"/"$outfile2"
