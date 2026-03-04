# SVETRI Branding & Identity

## The SVETRI Mascot

```
....                                                                  
...................                                                   
............                                                          
..........                                                            
.........                            .                                
........                            ..     .   .                      
........                           .''      ......                    
........                   ....   ..,;..    ......                    
.......                  ..';:lll:::ll;;,,'.. ...                     
......                  ..',:ldxkkxxdddkOOOd:,...                     
......                  ..',:ldxkO00KKKKXXX0dko:..                    
.....                  ...',:ldkOO0KKKKXXNNXkX0d;....                 
 ...                   ...',:cdkO0KKKKKXXNNNK0Xk; ....                
                       ...',:ldkO0KKKKXXXNNXOKXO, .....               
                       ....,:ldk0000KKXXNNNNX0Ok'  .....              
                      .......':dk0000KKK0000KKkx.  ......             
                    ...    ....;okO00Od:,;cx00xc .  .....             
                    .......':...,oOKOo,..';;dO0; .. ......            
                    ..,,,,,;;,..'dXX0d::cdxk0XK.  .........           
                    ..';clllc;'.,kNNNX0OOKXNNNl   .........           
                     ..,clooc'..c0NXXXXXNNNNN0.   ..........          
                     ..,:lodc..;dKNXKO0KXXXXK'     .........          
                     ..';ccc;,.,lOKXXOO0KXKO:      .........          
                      ..;:;'.',ldkXXXOkO00k'       ..........         
      ..               .';,'..,:lldxOOkOk:.         .........         
                     .   .'';:cloxk00Od;.           .........         
                   . ..   ..;ldOKXX0kc.             .........         
  .....     .         ...   .,ldxkxdo:'.             ...'.....        
........   ..       . ........lodxkxoc,.             ....'.....       
.',''''..  .        .. ....'''okkOOkxl'.              ....''.'.       
;:,'',;;.           .. ....,,'lkkkkxdc'.               ....'''..      
ooc::c;,..           .. ..'',;cxOOkkxo;.           .     ...''.'.     
odddkOOdc..            ...',':lxO00Okoc'.     .   ....    .'.''...    
lOOO0K0x;.            .....'';lxkOxdddl:.   ...   .....  .,.,''...    
kx00KKOo'.              ....,,:dk0KKKko,.. ....  ....   ..'..,,....   
00OKXKx:.         .....  ....,;lokO00k;.... ..  ...........''';...    
KX0OX0d..        . ..........';:lxKX0c'...  ....... ......','';....   
XNXk0Oo.           ...........,:o0K0o'....   .....     ...',,,;...    
KNXkkO:.     .     .........'.,cxK0d;'..    ....    .....'',:;:.      
XX0kod,.  .... ... .........',:okOkl;'.    ......  ..''..',;::c'      
XKOdcl'....... ... ........:cclldddd:'.    .... .  ..,;;'',::c:,.     
K0ko,:...  ..........'.'',,locccok0k:'.    .........';:c;,:::cc,.     
KOdc''.   ... ......'''',;::l:ldOXXO;..    .........':c:;c:lclc'..    
K0o;...   ... ......''',;;cdllxOXXXo'.............,;;:c::olllc:...    
KKd'...  ... .......'',;:loxxxOKXXx'....'',....'',:cc;clolllll;...    
ok0;.. . ..........'',;;llox0KXNN0'. .,,,,,'',',::lll:cdkoollc,...    
c:d:  .  ..........'',;;:okOKXNXKo ..,;c;,,',,,;:colodcxOoolc:'..     
```

## Project Name

**SVETRI** = **S**ecurity **V**erification **E**nterprise **T**ool **R**epository **I**ntelligence

A professional, intelligent security audit tool for GitHub repositories.

## Identity

- **Girl-face ASCII mascot** - Professional, friendly, approachable
- **Dotted character art style** - Modern, technical aesthetic  
- **Tagline**: "GitHub Security Intelligence"
- **Color scheme**: Terminal-friendly (works in all terminals)
- **Compatible**: All platforms (macOS, Linux, Windows via WSL)

## Where The Mascot Appears

The SVETRI mascot appears every time you run:

1. **Main audit command**
   ```bash
   ./scripts/audit_master.sh YOUR_USERNAME reports
   ```

2. **Security improvements command**
   ```bash
   ./scripts/apply_security_improvements.sh YOUR_USERNAME true
   ```

3. **Direct banner display**
   ```bash
   source lib/common.sh && show_svetri_banner
   ```

## Brand Guidelines

- ✅ Always display banner at tool startup
- ✅ Include ASCII art in all major output
- ✅ Use consistent logging with color codes
- ✅ Maintain professional tone in messages
- ✅ Show "SVETRI :: GitHub Security Intelligence" tagline
- ✅ Keep mascot centered in terminal output

## Design Philosophy

The SVETRI girl-face mascot represents:
- **Approachability** - Easy to use, not intimidating
- **Intelligence** - Advanced security analysis
- **Trust** - Professional, reliable tool
- **Care** - Designed with user experience in mind
- **Uniqueness** - Distinctive brand identity

## File Locations

- **Mascot Definition**: `lib/common.sh` (function: `show_svetri_banner()`)
- **Original Screenshot**: `Screenshot_20201122_100058.jpg`
- **ASCII Conversions**: `art_samples/screenshot_ascii_*.txt`
- **Source Image**: `Screenshot_20201122_100058.jpg` (width=70 ASCII art used)

## See Also

- [README.md](README.md) - Main documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [QUICKSTART.md](QUICKSTART.md) - Getting started
