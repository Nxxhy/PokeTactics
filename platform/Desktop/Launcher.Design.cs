using System.Text.Json;
using System.Drawing.Drawing2D;

partial class Launcher {
 readonly LanHost localHost=new();
 readonly System.Windows.Forms.Timer lanTimer=new() {Interval=1000};
 string lobbyEndpoint="";
 bool lanBusy;
 bool servingLocal;
 Label lanStatus=null!;
 TextBox lanAddress=null!,hostAddresses=null!;
 Button hostStart=null!,hostStop=null!,connectLan=null!;
 static readonly Color Forest=Color.FromArgb(40,88,64), Cream=Color.FromArgb(248,248,232), Mint=Color.FromArgb(184,216,160), Ink=Color.FromArgb(48,64,56);
 void BuildDesign() {
  MinimumSize=new Size(720,720);Size=new Size(900,840);
  var old=Body.Controls.Cast<Control>().ToArray();Body.Controls.Clear();Controls.Remove(Body);Body.Dispose();
  var root=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=1,RowCount=4,Padding=new Padding(16),BackColor=Forest};
  root.RowStyles.Add(new RowStyle(SizeType.Absolute,116));root.RowStyles.Add(new RowStyle(SizeType.Absolute,54));root.RowStyles.Add(new RowStyle(SizeType.Percent,100));root.RowStyles.Add(new RowStyle(SizeType.Absolute,72));
  Controls.Add(root);
  root.Controls.Add(new LauncherBanner {Dock=DockStyle.Fill,Font=Font,Margin=new Padding(0,0,0,12)},0,0);
  var navigation=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=2,Margin=new Padding(0)};
  navigation.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,50));navigation.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,50));root.Controls.Add(navigation,0,1);
  var pages=new Panel {Dock=DockStyle.Fill,BackColor=Cream,Padding=new Padding(12),Margin=new Padding(0)};root.Controls.Add(pages,0,2);
  var updatePage=Page();var lanPage=Page();pages.Controls.Add(updatePage);pages.Controls.Add(lanPage);
  var updatesTab=ActionButton("▶ SPIEL & UPDATES",()=>{});var lobbyTab=ActionButton("LAN-LOBBY",()=>{});
  updatesTab.Dock=lobbyTab.Dock=DockStyle.Fill;navigation.Controls.Add(updatesTab,0,0);navigation.Controls.Add(lobbyTab,1,0);
  void Select(bool lan) {updatePage.Visible=!lan;lanPage.Visible=lan;updatesTab.Text=lan?"SPIEL & UPDATES":"▶ SPIEL & UPDATES";lobbyTab.Text=lan?"▶ LAN-LOBBY":"LAN-LOBBY";updatesTab.BackColor=lan?Cream:Mint;lobbyTab.BackColor=lan?Mint:Cream;}
  updatesTab.Click+=(_,_)=>Select(false);lobbyTab.Click+=(_,_)=>Select(true);
  var exit=old[^1];
  foreach(var control in old.Skip(1)) {
   if(control==play||control==exit)continue;
   control.ForeColor=Ink;control.Margin=new Padding(0,4,0,10);
   if(control is Label l){l.AutoSize=false;l.UseCompatibleTextRendering=false;l.Height=Math.Max(38,l.Height);l.TextChanged+=(_,_)=>FitPage(updatePage);}
   if(control is Button b)StyleButton(b);
   updatePage.Controls.Add(control);
  }
  notes.Text="Hier erscheinen die Versionshinweise, sobald ein neues Update verfügbar ist.";
  notes.Height=150;notes.Font=new Font(Font.FontFamily,20,GraphicsUnit.Pixel);notes.BorderStyle=BorderStyle.FixedSingle;
  status.BackColor=Color.FromArgb(232,240,200);status.Padding=new Padding(10);status.Font=new Font(Font.FontFamily,22,GraphicsUnit.Pixel);
  versions.Font=new Font(Font.FontFamily,24,GraphicsUnit.Pixel);versions.ForeColor=Forest;
  var footer=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=2,Margin=new Padding(0,12,0,0)};
  footer.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,72));footer.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,28));
  StyleButton(play);play.Text="▶ SPIELEN";play.BackColor=Mint;play.Font=new Font(Font.FontFamily,26,GraphicsUnit.Pixel);play.Dock=DockStyle.Fill;
  StyleButton((Button)exit);exit.Dock=DockStyle.Fill;footer.Controls.Add(play,0,0);footer.Controls.Add(exit,1,0);root.Controls.Add(footer,0,3);
  BuildLanPage(lanPage);Select(false);
  Shown+=(_,_)=>{FitPage(updatePage);FitPage(lanPage);};
  lanTimer.Tick+=(_,_)=>{
   hostStart.Enabled=!lanBusy&&!localHost.Running&&!busy&&!GameRunning();
   hostStop.Enabled=!lanBusy&&localHost.Running&&!busy&&!GameRunning();
   connectLan.Enabled=!lanBusy&&!busy&&!GameRunning()&&!localHost.Running;
   if(!localHost.Running&&servingLocal) {
    servingLocal=false;hostAddresses.Clear();lobbyEndpoint=service.Endpoint;lanStatus.Text="Der lokale Server wurde beendet. Du kannst ihn erneut starten.";
   }
  };
  lanTimer.Start();Disposed+=(_,_)=>{lanTimer.Dispose();localHost.Dispose();};
 }
 FlowLayoutPanel Page() {
  var page=new FlowLayoutPanel {Dock=DockStyle.Fill,FlowDirection=FlowDirection.TopDown,WrapContents=false,AutoScroll=true,BackColor=Cream,Padding=new Padding(12)};
  page.SizeChanged+=(_,_)=>FitPage(page);return page;
 }
 static void FitPage(FlowLayoutPanel page) {
  foreach(Control c in page.Controls) {
   c.Width=Math.Max(160,page.ClientSize.Width-page.Padding.Horizontal-SystemInformation.VerticalScrollBarWidth-8);
   if(c is Label l)l.Height=Math.Max(32,TextRenderer.MeasureText(l.Text,l.Font,new Size(Math.Max(50,l.Width-l.Padding.Horizontal),0),TextFormatFlags.WordBreak|TextFormatFlags.NoPrefix).Height+l.Padding.Vertical+10);
  }
 }
 static void StyleButton(Button b) {b.FlatStyle=FlatStyle.Flat;b.FlatAppearance.BorderSize=3;b.FlatAppearance.BorderColor=Forest;b.FlatAppearance.MouseOverBackColor=Mint;b.FlatAppearance.MouseDownBackColor=Color.FromArgb(136,192,136);b.BackColor=Cream;b.ForeColor=Ink;b.Height=48;b.Margin=new Padding(3);b.UseCompatibleTextRendering=true;}
 Button ActionButton(string text,Action action) {var b=new Button {Text=text,Font=Font,AccessibleName=text};StyleButton(b);b.Click+=(_,_)=>action();return b;}
 Label Description(FlowLayoutPanel page,string text,int size=20) {var label=new Label {Text=text,Font=new Font(Font.FontFamily,size,GraphicsUnit.Pixel),ForeColor=Ink,Margin=new Padding(0,6,0,10)};label.TextChanged+=(_,_)=>FitPage(page);page.Controls.Add(label);return label;}
 void BuildLanPage(FlowLayoutPanel page) {
  lobbyEndpoint=service.Endpoint;
  Description(page,"TRAINER IM HEIMNETZ",28);
  Description(page,"Ein PC hostet, die anderen verbinden sich mit seiner Adresse. Im Spiel erstellt der Host eine Lobby und teilt den Lobby-Code.");
  lanStatus=Description(page,"Kein lokaler Server gestartet.");lanStatus.BackColor=Color.FromArgb(232,240,200);lanStatus.Padding=new Padding(8);
  Description(page,"1 · Lokalen Lobbyserver starten",24);
  var port=new NumericUpDown {Minimum=1024,Maximum=65535,Value=18790,Font=Font,AccessibleName="LAN-Port",BackColor=Cream};page.Controls.Add(port);
  hostStart=ActionButton("Server auf diesem PC starten",async()=>{
   if(lanBusy||busy||GameRunning())return;lanBusy=true;hostStart.Enabled=false;lanStatus.Text="Lobbyserver startet …";
   try {
    await localHost.Start(Directory.Exists(Path.Combine(home,"versions"))?ActiveDirectory:AppContext.BaseDirectory,(int)port.Value,version);
    lobbyEndpoint=$"http://127.0.0.1:{localHost.Port}";
    servingLocal=true;
    var addresses=LanHost.Addresses(localHost.Port);hostAddresses.Text=string.Join(Environment.NewLine,addresses);
    lanStatus.Text=addresses.Length>0?"Server läuft. Teile eine der unten angezeigten Adressen mit deinen Freunden. Dann SPIELEN und Lobby erstellen wählen.":"Server läuft nur auf diesem PC. Kein privates IPv4-Netz gefunden. Bitte WLAN/LAN prüfen.";
   }catch(Exception e){lanStatus.Text=e.Message;}finally{lanBusy=false;}
  });page.Controls.Add(hostStart);
  hostAddresses=new TextBox {ReadOnly=true,Multiline=true,Height=64,BackColor=Color.FromArgb(232,240,200),Font=Font,ScrollBars=ScrollBars.Vertical,AccessibleName="Host-Adressen zum Teilen"};page.Controls.Add(hostAddresses);
  page.Controls.Add(ActionButton("Host-Adressen kopieren",()=>{if(hostAddresses.Text.Length>0)Clipboard.SetText(hostAddresses.Text);}));
  hostStop=ActionButton("Lokalen Server beenden",()=>{if(GameRunning()||busy)return;localHost.Stop();servingLocal=false;hostAddresses.Clear();lobbyEndpoint=service.Endpoint;lanStatus.Text="Lokaler Server beendet. Bestehende Lobbys sind geschlossen.";});hostStop.Enabled=false;page.Controls.Add(hostStop);
  Description(page,"2 · Mit einem anderen Host verbinden",24);
  lanAddress=new TextBox {Font=Font,BackColor=Cream,PlaceholderText="192.168.178.20:18790",AccessibleName="Adresse des Lobby-Hosts"};page.Controls.Add(lanAddress);
  var saved=Path.Combine(home,"lan.json");try{if(File.Exists(saved))lanAddress.Text=Files.Read<Service>(saved).Endpoint;}catch{}
  connectLan=ActionButton("Adresse prüfen & verwenden",async()=>{
   if(lanBusy||busy||GameRunning()||localHost.Running)return;lanBusy=true;connectLan.Enabled=false;
   try{var uri=LanHost.Endpoint(lanAddress.Text);await LanHost.Probe(uri,version:version);lobbyEndpoint=uri.ToString().TrimEnd('/');Files.Atomic(saved,JsonSerializer.Serialize(new Service(lobbyEndpoint),Files.Json));lanStatus.Text="Verbunden mit "+lobbyEndpoint+". Jetzt SPIELEN wählen und im Spiel mit dem Lobby-Code beitreten.";}
   catch(Exception e){lanStatus.Text="Verbindung nicht möglich: "+e.Message;}finally{lanBusy=false;}
  });page.Controls.Add(connectLan);
  page.Controls.Add(ActionButton("Konfigurierten Online-Dienst verwenden",()=>{if(GameRunning()||busy||localHost.Running)return;lobbyEndpoint=service.Endpoint;lanStatus.Text=service.Endpoint.Length>0?"Online-Dienst ausgewählt.":"Noch kein öffentlicher Lobby-Dienst eingerichtet.";}));
  Description(page,"Windows-Firewall: Zugriff für private Netzwerke erlauben. Beide PCs müssen im selben LAN/WLAN sein. Keine Router-Portfreigabe nötig. Der Host-Launcher bleibt geöffnet. Die Online-Versionsprüfung bleibt Pflicht.",18);
  Description(page,"Gemeinsame Partien für 2–8 Trainer: Alle melden sich bereit, dann startet der Host. Drei Leben pro Trainer – das letzte verbleibende Team gewinnt.",18);
 }
}

sealed class LauncherBanner : Control {
 public LauncherBanner(){DoubleBuffered=true;BackColor=Color.FromArgb(88,152,104);}
 protected override void OnPaint(PaintEventArgs e) {
  base.OnPaint(e);var g=e.Graphics;g.SmoothingMode=SmoothingMode.None;
  using var dark=new SolidBrush(Color.FromArgb(40,88,64));using var pale=new SolidBrush(Color.FromArgb(232,240,200));using var red=new SolidBrush(Color.FromArgb(192,72,64));
  for(int x=0;x<Width;x+=24){g.FillRectangle(dark,x,Height-12,8,8);g.FillRectangle(pale,x+8,Height-8,4,4);}
  g.FillRectangle(dark,16,18,64,64);g.FillRectangle(red,22,24,52,24);g.FillRectangle(pale,22,54,52,22);g.FillRectangle(dark,38,40,24,24);g.FillRectangle(pale,44,46,12,12);
  using var title=new Font(Font.FontFamily,34,GraphicsUnit.Pixel);using var subtitle=new Font(Font.FontFamily,20,GraphicsUnit.Pixel);
  TextRenderer.DrawText(g,"POKÉ TACTICS",title,new Rectangle(100,18,Width-108,42),pale.Color,TextFormatFlags.NoPrefix|TextFormatFlags.SingleLine);
  TextRenderer.DrawText(g,"DEIN TEAM. DEINE TAKTIK.",subtitle,new Rectangle(102,60,Width-108,28),pale.Color,TextFormatFlags.NoPrefix|TextFormatFlags.SingleLine);
 }
}
