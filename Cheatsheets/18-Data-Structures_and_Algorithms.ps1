###################################################
# Data Structures and Algorithms
###################################################

<#
 This is a silly one:
 You may one day be asked to create a func that could take $start and $end
 and reverse anything in an array within the given range
 based on an arbitrary array without mutating the original array.
 Let's see one way to do that and introduce another data structure.
#>

$targetArray = 'a','b','c','d','e','f','g','h','i','j','k','l','m'

function Format-Range ($start, $end, $array) {
    [System.Collections.ArrayList]$firstSectionArray = @()
    [System.Collections.ArrayList]$secondSectionArray = @()
    [System.Collections.Stack]$stack = @()
    for ($index = 0; $index -lt $array.Count; $index++) {
        if ($index -lt $start) {
            $firstSectionArray.Add($array[$index]) > $null
        }
        elseif ($index -ge $start -and $index -le $end) {
            $stack.Push($array[$index])
        }
        else {
            $secondSectionArray.Add($array[$index]) > $null
        }
    }
    $finalArray = $firstSectionArray + $stack.ToArray() + $secondSectionArray
    return $finalArray
}

Format-Range 2 6 $targetArray
# => 'a','b','g','f','e','d','c','h','i','j','k','l','m'

# The previous method works, but uses extra memory by allocating new arrays.
# It's also kind of lengthy.
# Let's see how we can do this without allocating a new array.
# This is slightly faster as well.

function Format-Range ($start, $end) {
  while ($start -lt $end)
  {
      $temp = $targetArray[$start]
      $targetArray[$start] = $targetArray[$end]
      $targetArray[$end] = $temp
      $start++
      $end--
  }
  return $targetArray
}

Format-Range 2 6 # => 'a','b','g','f','e','d','c','h','i','j','k','l','m'
