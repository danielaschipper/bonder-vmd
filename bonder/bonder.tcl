##
## bonder 1.0
##
##

## Tell Tcl that we're a package and any dependencies we may have
package provide bonder 1.0

namespace eval Bonder:: {
  namespace export bonder

  # window handles
  variable w                                          ;# handle to main window
  # lines
  variable point1
  variable point2
  variable point3
  variable point4
  variable bondType
  variable focusWindow
  variable res
  variable cutoff
  variable cube
  variable drawMol
  variable minRho
  variable maxRho
}

#
# Create the window and initialize data structures
#
proc Bonder::bonder {} {
  variable w
  variable point1
  variable point2
  variable point3
  variable point4
  variable bondType

  # If already initialized, just turn on
  if { [winfo exists .textview] } {
    wm deiconify $w
      return
  }
  set w [toplevel ".bonder"]
  wm title $w "bonder"
  wm resizable $w 0 0
  frame $w.bondType
  grid $w.bondType -padx 10 -pady 10
  radiobutton $w.bondType.lineBtn -text "Line"   -variable bondType -value "line" -command Bonder::line 
  grid $w.bondType.lineBtn -row 1 -column 2
  radiobutton $w.bondType.trigBtn -text "Trig"   -variable bondType -value "trig" -command Bonder::trig
  grid $w.bondType.trigBtn -row 1 -column 3
  radiobutton $w.bondType.quadBtn -text "Quad"   -variable bondType -value "quad" -command Bonder::quad
  grid $w.bondType.quadBtn -row 1  -column 4
  $w.bondType.lineBtn select

  frame $w.selectors
  grid $w.selectors -padx 10 -pady 10
  entry $w.selectors.text1 -text ""   -textvariable Bonder::point1 -width 5 -validate focusin -vcmd {Bonder::tex1sel}
  grid $w.selectors.text1 -row 2 -column 3
  entry $w.selectors.text2 -text ""   -textvariable Bonder::point2 -width 5 -validate focusin -vcmd {Bonder::tex2sel}
  grid $w.selectors.text2 -row 2 -column 5
  entry $w.selectors.text3 -text ""   -textvariable Bonder::point3 -width 5 -validate focusin -vcmd {Bonder::tex3sel}
  grid $w.selectors.text3 -row 2 -column 7
  entry $w.selectors.text4 -text ""   -textvariable Bonder::point4 -width 5 -validate focusin -vcmd {Bonder::tex4sel}
  grid $w.selectors.text4 -row 2 -column 9
  label $w.selectors.myLabel1 -text "Atom 1" 
  grid $w.selectors.myLabel1 -row 2 -column 2
  label $w.selectors.myLabel2 -text "Atom 2" 
  grid $w.selectors.myLabel2 -row 2 -column 4
  label $w.selectors.myLabel3 -text "Atom 3" 
  grid $w.selectors.myLabel3 -row 2 -column 6
  label $w.selectors.myLabel4 -text "Atom 4" 
  grid $w.selectors.myLabel4 -row 2 -column 8
  Bonder::line
  set bondType "line"

  frame $w.options
  grid $w.options -padx 10 -pady 10
  entry $w.options.text1 -text "0.02"   -textvariable Bonder::res -width 5 
  grid $w.options.text1 -row 3 -column 3
  entry $w.options.text2 -text "0.5"   -textvariable Bonder::cutoff -width 5 
  grid $w.options.text2 -row 3 -column 5
  radiobutton $w.options.lowbtn -text "Low image resolution "   -variable Bonder::cube -value "5"
  #entry $w.options.text3 -text "1"   -textvariable Bonder::cube -width 5
  grid $w.options.lowbtn -row 3 -column 6
  radiobutton $w.options.highbtn -text "High image resolution"   -variable Bonder::cube -value "1"
  #entry $w.options.text3 -text "1"   -textvariable Bonder::cube -width 5
  grid $w.options.highbtn -row 4 -column 6

  label $w.options.myLabel1 -text "Resolution" 
  grid $w.options.myLabel1 -row 3 -column 2
  label $w.options.myLabel2 -text "RDG cutoff" 
  grid $w.options.myLabel2 -row 3 -column 4
  #label $w.options.myLabel3 -text "Cube factor" 
  #grid $w.options.myLabel3 -row 3 -column 6
  
  entry $w.options.text4 -text "-0.02"   -textvariable Bonder::minRho -width 5   
  grid $w.options.text4 -row 4 -column 3
  entry $w.options.text5 -text "0.02"   -textvariable Bonder::maxRho -width 5
  grid $w.options.text5 -row 4 -column 5
  label $w.options.myLabel4 -text "Minmium rho color"
  grid $w.options.myLabel4 -row 4 -column 2
  label $w.options.myLabel5 -text "Maximium rho color"
  grid $w.options.myLabel5 -row 4 -column 4
  set Bonder::minRho -0.02
  set Bonder::maxRho 0.02

  
  
  frame $w.exacute
  grid $w.exacute -padx 10 -pady 10
  button $w.exacute.launch -text "Launch" -command Bonder::launch
  grid $w.exacute.launch -row 3 -column 2
  button $w.exacute.launchA -text "Background" -command Bonder::launchA
  grid $w.exacute.launchA -row 3 -column 3
  button $w.exacute.save -text "Save" -command Bonder::save
  grid $w.exacute.save -row 3 -column 4
  set Bonder::res 0.02
  set Bonder::cutoff 0.5
  set Bonder::cube 1

  trace add variable ::vmd_pick_event write Bonder::picked
  trace add variable point1 write [list Bonder::firstChange $Bonder::point1]
  trace add variable point2 write [list Bonder::secondChange $Bonder::point2]
  trace add variable point3 write [list Bonder::thirdChange $Bonder::point3]
  trace add variable point4 write [list Bonder::fourthChange $Bonder::point4]
  focus -force $w.selectors.text1 
}

proc Bonder::tex1sel {} {
  variable focusWindow
  set focusWindow 0
  return 1
}
proc Bonder::tex2sel {} {
  variable focusWindow
  set focusWindow 1
  return 1
}

proc Bonder::tex3sel {} {
  variable focusWindow
  set focusWindow 2
  return 1
}

proc Bonder::tex4sel {} {
  variable focusWindow
  set focusWindow 3
  return 1
}


proc Bonder::picked {args} {
  variable w
  variable focusWindow
  #variable point1
  #variable point2
  #variable point3
  #variable point4
  variable bondType
  switch $focusWindow {
    "0" {
      set Bonder::point1 $::vmd_pick_atom
    } "1" {
      set Bonder::point2 $::vmd_pick_atom
    } "2" {
      set Bonder::point3 $::vmd_pick_atom
    } "3" {
      set Bonder::point4 $::vmd_pick_atom
    }
  }
  
  switch $bondType {
    "line" {
      set count 2
    } "trig" {
      set count 3
    } "quad" {
      set count 4
    }
  }

  set focusWindow [expr {($focusWindow + 1) % $count }]
}

proc Bonder::line {} {
  variable w
  variable bondType
  set bondType "line"
  $w.selectors.myLabel3 configure -state disable
  $w.selectors.myLabel4 configure -state disable
  Bonder::DrawChoose
}

proc Bonder::trig {} {
  variable w
  variable bondType
  set bondType "trig"
  $w.selectors.myLabel3 configure -state active
  $w.selectors.myLabel4 configure -state disable
  Bonder::DrawChoose
}

proc Bonder::quad {} {
  variable w
  variable bondType
  set bondType "quad"
  $w.selectors.myLabel3 configure -state active
  $w.selectors.myLabel4 configure -state active
  Bonder::DrawChoose
}

proc Bonder::firstChange {oldval varname element op} {
  upvar 2 $varname localvar
  if { [string is integer $localvar] } {
    Bonder::DrawChoose
  } else {
    set localvar $oldval
  }
}

proc Bonder::secondChange {oldval varname element op} {
  upvar 2 $varname localvar
  if { [string is integer $localvar] } {
    Bonder::DrawChoose
  } else {
    set localvar $oldval
  }
}

proc Bonder::thirdChange {oldval varname element op} {
  upvar 2 $varname localvar
  if { [string is integer $localvar] } {
    Bonder::DrawChoose
  } else {
    set localvar $oldval
  }
}

proc Bonder::fourthChange {oldval varname element op} {
  upvar 2 $varname localvar
  if { [string is integer $localvar] } {
    Bonder::DrawChoose
  } else {
    set localvar $oldval
  }
}

proc Bonder::DrawChoose {} {
  variable bondType
  switch $bondType {
    "line" {
      Bonder::DrawLine
    } "trig" {
      Bonder::DrawTrig
    } "quad" {
      Bonder::DrawQuad
    }
  }
}

proc Bonder::DrawLine {} {
  variable point1
  variable point2
  if {$point1 eq ""} {return}
  if {$point2 eq ""} {return}


  set sel [atomselect top "index $point1"]
  set atom1 [$sel get "x y z"]
  set atom1 [join $atom1 " "]
  set sel [atomselect top "index $point2"]
  set atom2 [$sel get "x y z"]
  set atom2 [join $atom2 " "]

  graphics top delete all
  graphics top line $atom1 $atom2 

}


proc Bonder::DrawTrig {} {
  variable point1
  variable point2
  variable point3

  graphics top delete all

  if {$point1 eq ""} {return}
  if {$point2 eq ""} {return}
  set sel [atomselect top "index $point1"]
  set atom1 [$sel get "x y z"]
  set atom1 [join $atom1 " "]
  set sel [atomselect top "index $point2"]
  set atom2 [$sel get "x y z"]
  set atom2 [join $atom2 " "]

  graphics top line $atom1 $atom2 style dashed

  if {$point3 eq ""} {return}

  set sel [atomselect top "index $point3"]
  set atom3 [$sel get "x y z"]
  set atom3 [join $atom3 " "]



  graphics top line [vecscale [vecadd $atom1 $atom2] 0.5] $atom3 style solid 
}

proc Bonder::DrawQuad {} {
  variable point1
  variable point2
  variable point3
  variable point4

  graphics top delete all

  if {$point1 eq ""} {return}
  if {$point2 eq ""} {return}
  set sel [atomselect top "index $point1"]
  set atom1 [$sel get "x y z"]
  set atom1 [join $atom1 " "]
  set sel [atomselect top "index $point2"]
  set atom2 [$sel get "x y z"]
  set atom2 [join $atom2 " "]

  graphics top line $atom1 $atom2 style dashed

  if {$point3 eq ""} {return}
  if {$point4 eq ""} {return}

  set sel [atomselect top "index $point3"]
  set atom3 [$sel get "x y z"]
  set atom3 [join $atom3 " "]
  set sel [atomselect top "index $point4"]
  set atom4 [$sel get "x y z"]
  set atom4 [join $atom4 " "]

  graphics top line $atom3 $atom4 style dashed

  graphics top line [vecscale [vecadd $atom1 $atom2] 0.5] [vecscale [vecadd $atom3 $atom4] 0.5] style solid 

}

proc Bonder::launch {} {
  variable point1
  variable point2
  variable point3
  variable point4
  variable bondType
  variable w
  
  if {$point1 eq ""} {return}
  if {$point2 eq ""} {return}
  cd [file dirname [molinfo top get filename]]
  file mkdir [file rootname [file tail [molinfo top get filename]]]
  set output [file rootname [file tail [molinfo top get filename]]]/output
  $w.exacute.launch configure -text "Running"
  set name [file rootname [file tail [molinfo top get filename]]]
  switch $bondType {
    "line" {
      exec bonder line -i [molinfo top get filename] -1 $point1 -2 $point2 -r $Bonder::res -c $Bonder::cutoff -o $output -q $Bonder::cube >@stdout
    } "trig" {
      if {$point3 eq "" } {return }
      exec bonder bond trig -i [molinfo top get filename] -1 $point1 -2 $point2 -3 $point3 -r $Bonder::res -c $Bonder::cutoff -o $output -q $Bonder::cube >@stdout
    } "quad" {
      if {$point3 eq ""} {return }
      if {$point4 eq ""} {return }
      exec bonder bond quad -i [molinfo top get filename] -1 $point1 -2 $point2 -3 $point3 -4 $point4 -r $Bonder::res -c $Bonder::cutoff -o $output -q $Bonder::cube >@stdout
    }
  }
  cd [file rootname [file tail [molinfo top get filename]]]
  exec  agenvmd $Bonder::cutoff $Bonder::minRho $Bonder::maxRho
  graphics top delete all
  source all.vmd
  Bonder::DrawChoose
  exec bonder minsum -ignorestderr
  set fp [open $name.sum ]

  set dataWin [toplevel ".bonderOutputFile"] 
  wm title $dataWin $name
  wm resizable $dataWin 0 0
  frame $dataWin.data
  grid $dataWin.data -padx 10 -pady 10
  message $dataWin.data.outputText -text [concat  "name,               volume, kinetic energy, potental energy, total energy, elf, rho\\\n" [read $fp] ] -width 1000
  grid $dataWin.data.outputText
  close $fp

  $w.exacute.launch configure -text "Launch"
}

proc Bonder::launchA {} {
  variable point1
  variable point2
  variable point3
  variable point4
  variable bondType
  variable w
  
  if {$point1 eq ""} {return}
  if {$point2 eq ""} {return}
  cd [file dirname [molinfo top get filename]]
  file mkdir [file rootname [file tail [molinfo top get filename]]]
  set output [file rootname [file tail [molinfo top get filename]]]/output
  set name [file rootname [file tail [molinfo top get filename]]]
  switch $bondType {
    "line" {
      exec bonder mixed $Bonder::cutoff $Bonder::minRho $Bonder::maxRho [file rootname [file tail [molinfo top get filename]]] l [molinfo top get filename] $point1 $point2 $Bonder::res $Bonder::cutoff $output $Bonder::cube  >@stdout &
    } "trig" {
      if {$point3 eq "" } {return }
      exec bonder mixed $Bonder::cutoff $Bonder::minRho $Bonder::maxRho [file rootname [file tail [molinfo top get filename]]] t [molinfo top get filename] $point1 $point2 $point3 $Bonder::res $Bonder::cutoff $output $Bonder::cube  >@stdout &
    } "quad" {
      if {$point3 eq ""} {return }
      if {$point4 eq ""} {return }
      exec bonder mixed $Bonder::cutoff $Bonder::minRho $Bonder::maxRho [file rootname [file tail [molinfo top get filename]]] q [molinfo top get filename] $point1 $point2 $point3 $point4 $Bonder::res $Bonder::cutoff $output $Bonder::cube  >@stdout &
    }
  }
}
proc Bonder::save {} {
  variable point1
  variable point2
  variable point3
  variable point4
  variable bondType
  variable w
  
  if {$point1 eq ""} {return}
  if {$point2 eq ""} {return}
  cd [file dirname [molinfo top get filename]]
  
  switch $bondType {
    "line" {
      set outputtext "./bonder line -i [molinfo top get filename] -1 $point1 -2 $point2 -r $Bonder::res -c $Bonder::cutoff -o output -q $Bonder::cube"
    } "trig" {
      if {$point3 eq "" } {return }
      set outputtext "./bonder trig -i [molinfo top get filename] -1 $point1 -2 $point2 -3 $point3 -r $Bonder::res -c $Bonder::cutoff -o output -q $Bonder::cube"
    } "quad" {
      if {$point3 eq ""} {return }
      if {$point4 eq ""} {return }
       set outputtext "./bonder quad -i [molinfo top get filename] -1 $point1 -2 $point2 -3 $point3 -4 $point4 -r $Bonder::res -c $Bonder::cutoff -o output -q $Bonder::cube"
    }
  }
  file mkdir [file rootname [file tail [molinfo top get filename]]]
  set outfile [open [file rootname [file tail [molinfo top get filename]]]/run.sh w]
  puts $outfile $outputtext
  close $outfile
  set bondFile  [exec which bonder]
  file copy -force [molinfo top get filename] [file rootname [file tail [molinfo top get filename]]]
  file copy -force [file dirname $bondFile]/bonder [file rootname [file tail [molinfo top get filename]]]

  tk_messageBox -message "Bonder portable has been created in [file rootname [file tail [molinfo top get filename]]] run.sh will run it" -type ok -title done -parent $w
}

proc bonder_tk {} {
  Bonder::bonder
  return $Bonder::w
}


