# AKIT2 SS18, Hauptklausur, 15.6.2018
library(ggplot2)
library(car)
library(corrplot)
library(effects)
library(pwr)
library(ROCR)
library(runjags)
library(coda)
rjags::load.module("glm")
library(akit2)

df <- read.csv('C:\\Users\\Dominik\\Downloads\\deformation.csv')
# Referenz-Gruppe ändern
df$material = relevel(df$material, ref = 'holz')

# Wir arbeiten an einer industriellen Sortieranlage, welche in einem der Verarbeitungsschritte
# Material siebt. Das Sieb wird mit der Zeit verformt und muss ersetzt werden. Wir wollen
# in einer Studie die entstehende Deformation des Siebes erheben.

# Der Datensatz enth�lt:
# - durchsatz ... wie viel Material (Volumen) gesiebt wird (Kubikdezimeter pro Stunde, dm^3/h)
# - masse ... Masse der einzelnen Teile (mg)
# - geschwindigkeit ... Geschwindigkeit mit der Teile auf Sieb treffen (m/s)
# - material ... Art der Teile
# - deformation ... Ma� f�r entstandene Deformation des Siebs

view(df)
#Durchsatz sieht nicht gut aus. Genauer anschauen.

hist(df$durchsatz)
#Ist aber Normalverteilt. Gut.
hist(df$deform)
hist(df$masse) #Masse ist etwas Linkslastig
hist(df$geschw)

plot(df$deform~df$masse)
plot(df$deform~log2(df$masse))
#Sieht log-transformiert schon Besser aus.
hist(log2(df$masse))

# Schritt 1: Wir werden zwei Modelle vergleichen: mit und ohne Interaktion.
#            Das Interaktionsmodell nimmt auch die Interaktionen zwischen Masse
#            und Geschwindigkeit mit auf.
#            Berechnen Sie getrennt f�r beide Modelle, wie viele Datens�tze wir
#            mindestens ben�tigen, um einen Modelleffekt mit f²=0.05 mit einer
#            Wahrscheinlichkeit von 95% zu erkennen.
#
#            Nehmen Sie dann mittels df[1:___,] nur so viele Eintr�ge aus dem Datensatz,
#            wie die gr��ere der beiden Power-Analysen ergibt.
#
#            Falls Sie diesen Schritt auslassen wollen:
#            Verwenden Sie 450 Datensätze.
power=pwr.f2.test(u= 6, f2=0.05 ,power= 0.95)
n = round(power$v+6+1)
#n = 423
power2=pwr.f2.test(u= 7, f2=0.05 ,power= 0.95)
n2 = round(power2$v+7+1)
#n2 = 444

dfn=df[1:445,]

# Schritt 2: Erstellen Sie das lineare Modell ohne Interaktion.
#            Verifizieren & interpretieren Sie das Modell.
model1=lm(deform~masse+material+geschw+durchsatz,data=dfn)

########################### Model Tests ###############################

#------------------------------------------------Kolinearit�t 
vif(model1)
#Alle Werte befinden sich unter 3 daher ist nur eine Geringe Abh�ngigkeit zu bemerken

#----------------------------------------------Homogene Varianz 
par(mfrow=c(2,2))
plot(model1)
#kleine Werte m�ssen dieselbe Varianz haben wie gro�e Werte, 
#andernfalls sind Induktionen auf die Gesamtpopulation schwierig bzw. fehlerhaft.
#hier liegen aber keine Muster vor daher k�nnen wir weiter machen

#------------------------------------------Normalverteilte Residuen
hist(model1$residuals)

qqp(model1) 
#Die Werte liegen innerhalb der Blauen Grenzen, sieht also gut aus

#--------------------------------------------Lineare Abh�ngigkeit 
crPlots(model1)
#In unserem Fall sind die Blaue Line (SOLL) und die Pinke Linie (IST) nahezu 
#deckungsgleich daher sieht das ganz gut aus und wir k�nnen weiter machen

########################### Ausrei�er Tests ###############################
outlierTest(model1)
plot(model1, which=4)
#Alles unter 0.5. Sieht gut aus.
plot(model1, which=5)
#Unsere Werte liegen unter 0.5 daher gibt es keine Ausrei�er, dass kann man auch im Leverage 
#test sehen, weshlab wir hier mit unserem Model weiter machen k�nnen.

#######_Berechnen der Bedeutsamkeit der Variablen innerhalb meines Modells_########
m1.aov = Anova(model1, type=2) #--> type3 w�rde den Intercept mitanzeigen
ssq = m1.aov[,1]
names(ssq) = rownames(m1.aov) #Ergebnis passende Namen geben
ssq / m1.aov["Residuals",1]
#Masse �ndert die RSS um 32%
#Geschwindigkeit �ndert RSS um 23%
#Durchsatz �ndert RSS um 7%
#Material �ndert RSS um 0.9%
#Demnach kann entnommen werden das die Variable Masse den st�rksten Effekt hat 
  #und demnach auch am meisten zu unserem Model beitr�gt.

drop1(model1) #AIC interpretiern und gr��er ist besser
drop1(model1)[order(drop1(model1)[,4]),]
#Auch hier sehen wir das Masse am meisten zu unserem Modell beitr�gt.
#Material verschl�chtert unser Modell sogar.

######################## Interpretation ##########################
# Der Datensatz enth�lt:
# - durchsatz ... wie viel Material (Volumen) gesiebt wird (Kubikdezimeter pro Stunde, dm^3/h)
# - masse ... Masse der einzelnen Teile (mg)
# - geschwindigkeit ... Geschwindigkeit mit der Teile auf Sieb treffen (m/s)
# - material ... Art der Teile
# - deformation ... Ma� f�r entstandene Deformation des Siebs
summary(model1)
2.886e+02
#Der Basisfall ist mit Material Holz und alle anderen Werte sind auf 0 (nicht sinnvoll). Hier
#liegt der Deformationswert bei 288.6.
4.348e-01
#Bei erh�hung der Masse um 1mg steigt die Deformation um 0.4348
3.323e+00
#Wenn als material Eisen verwendet wird steigt die Deformation um 3.323


# Schritt 3: Erstellen Sie das lineare Modell mit Interaktionen zwischen
#            Masse und Geschwindigkeit.
#            Verifizieren & interpretieren Sie das Modell.
model2=lm(deform~masse+material+geschw+durchsatz+masse:geschw,data=dfn)

########################### Model Tests ###############################

#------------------------------------------------Kolinearit�t 
vif(model2)
#masse und geschw korrelieren wohl mit dem Interaktionsterm.
#Andere Werte schauen ok aus.
cor(dfn$masse, dfn$masse*dfn$geschw) #Korreliert stark mit 0.83
cor(dfn$geschw, dfn$geschw*dfn$masse) #Korreliert leicht mit 0.46

#----------------------------------------------Homogene Varianz 
par(mfrow=c(2,2))
plot(model2)
#kleine Werte m�ssen dieselbe Varianz haben wie gro�e Werte, 
#andernfalls sind Induktionen auf die Gesamtpopulation schwierig bzw. fehlerhaft.
#hier liegen aber keine Muster vor daher k�nnen wir weiter machen

#------------------------------------------Normalverteilte Residuen
hist(model2$residuals)

qqp(model2) 
#Die Werte verlassen kurz unten die blaue Linie. Sieht aber noch ok aus.

########################### Ausrei�er Tests ###############################
outlierTest(model2)
plot(model2, which=4)
#Alles unter 0.5. Sieht gut aus.
plot(model2, which=5)
#Unsere Werte liegen unter 0.5 daher gibt es keine Ausrei�er, dass kann man auch im Leverage 
#test sehen, weshlab wir hier mit unserem Model weiter machen k�nnen.

#######_Berechnen der Bedeutsamkeit der Variablen innerhalb meines Modells_########
Anova(model2, type=3)
#durchsatz hat nun am meisten Einfluss auf unser Modell.
#Interaktionsterm hat am Zweitmeisten Einfluss. Alle anderen Werte sind weit unterhalb.

drop1(model2) #AIC interpretiern und gr��er ist besser
drop1(model2)[order(drop1(model2)[,4]),]
#Auch hier sehen wir das durchsatz am meisten zu unserem Modell beitr�gt.
#Material verschl�chtert unser Modell sogar.

######################## Interpretation ##########################
# Der Datensatz enth�lt:
# - durchsatz ... wie viel Material (Volumen) gesiebt wird (Kubikdezimeter pro Stunde, dm^3/h)
# - masse ... Masse der einzelnen Teile (mg)
# - geschwindigkeit ... Geschwindigkeit mit der Teile auf Sieb treffen (m/s)
# - material ... Art der Teile
# - deformation ... Ma� f�r entstandene Deformation des Siebs
summary(model2)
3.001e+02
#Der Basisfall ist mit Material Holz und alle anderen Werte sind auf 0 (nicht sinnvoll). Hier
#liegt der Deformationswert bei 300.1.
8.655e-04
#Bei erh�hung des Durchsatzes um 1dm^3/h steigt die Deformation um 0.0008655
4.089e+00
#Wenn als material Eisen verwendet wird steigt die Deformation um 4.089
#masse:geschw = 5.445e-0
#Wie interpretieren wir hier den Interaktionsterm?


# Schritt 4: Welches der beiden Modelle ist aussagekr�ftiger?
#            �berpr�fen Sie Ihre Einsch�tzung:
#            Wir erhalten zus�tzlich weitere 100 Datens�tze: df[901:1000,]
#            Sagen Sie f�r beide Modelle die Deformierungs-Werte dieser Datens�tze vorher
#            und vergleichen Sie sie mit den echten Werten aus dem Datensatz.
#            Welches Modell hat in Summe weniger Abweichung?
#
#            Tipp: Damit sich Abweichungen nicht aufheben, sollten Sie sie quadrieren
#                  (--> sum of squares)

######################## Modelle vergleichen ##########################
summary(model1)
#Adjusted R-squared:  0.5318
summary(model2)
#Adjusted R-squared:  0.5466
#model2 erkl�rt Besser als model1. Interaktionsterm ist signifikant.

#--------------------------------------------anova 
anova(model1, model2)
#RSS ist bei model2 kleiner und somit Besser als bei model1.

#---------------------------------------------AIC 
AIC(model1, model2)
#Gleiches Ergebniss wie bei anova.

########################### Vorhersagen ##################################
#----------------Vorhersagegenauigkeit berechnen
#vorhersage des kompletten Models mit den jeweiligen Testdaten
dfp=df[901:1000,]
p1 = predict(model1, dfp)
p2 = predict(model2, dfp)
#echte Daten -vorhersage daten rechnen quadrieren wegen sum of squares
ssq1 = sum((dfp$deform - p1)^2)
ssq2 = sum((dfp$deform - p2)^2)
c(ssq1, ssq2)
#model2 sagt die Werte besser vorher weil es weniger Abweichungen gibt als bei model1.


# Schritt 5: Zeichnen Sie ein Diagramm Deformation vs. Geschwindigkeit f�r mindestens
#            drei typische Massen, Durchsatz durchschnittlich, Material: Eisen.
#            Ist die Interaktion ersichtlich? Wie kann sie interpretiert werden?
#            
#            Alternativ: berechnen Sie Intercept und Steigung dieser drei partiellen
#                        Regressionsgeraden mit drei typische Massen, Durchsatz durchschnittlich,
#                        Material: Eisen.
#---------------------Grafiken f�r interaktionsterme

plot(effect(term='masse:geschw', mod=model2, x.var="geschw"))
#AW: wir sehen das sich die steigung und die Intercept �ndern
#intercept = die h�he der linie
#steitgung = neigung der linie


#----------------------Berechnung von Steigung und Intercept
#Berechnung von Intercept und steigung einer regressionsgeraden
quantile1 = quantile(dfn$masse, 0.25)
quantile2 = quantile(dfn$masse, 0.5)
quantile3 = quantile(dfn$masse, 0.75)
c(quantile1,quantile2,quantile3)

#F�r x,y,z die gefragten Predictwerte eintragen
#ACHTUNG: MASSE ist der Part des Interaktionsterm der in mehreren Stufen dargestellt werden soll
#der Zweite Teil des Interaktionsterm z.b Geschwindigkeit ist beim Intercept auf 0 zusetzen
intcpt = predict(model2, data.frame(masse=c(quantile1, quantile2, quantile3),
                                    material="eisen",
                                    geschw=0,
                                    durchsatz=mean(dfn$durchsatz)))
intcpt
#der Zweite Teil des Interaktionsterm z.b Geschwindigkeit ist der Steigung auf 1 zusetzen
steig = predict(model2, data.frame(masse=c(quantile1, quantile2, quantile3),
                                 material="eisen",
                                 geschw=1,
                                 durchsatz=mean(dfn$durchsatz))) - intcpt
steig
#Wir sehen das sich sowohl der Intercept bei den dargestellelten Quantielen  also auch der 
#Steigung  �ndern, was auf eine Interaktion schlie�en l�sst


# Schritt 6: a) Bei einer Holz-Anlage, mit mittlerer Geschwindigkeit und Masse:
#               ab welchem Durchsatz wird die Deformation gr��er 325?

#Berechnen ab wann ein bestimmter Wert der abh�ngigen Variable eintritt
seq=seq(min(dfn$durchsatz),max(dfn$durchsatz),length.out = 1000)
pred_gesucht=predict(model2, data.frame(material="holz",
                                        geschw=mean(dfn$geschw),
                                        masse=mean(dfn$masse),
                                        durchsatz=seq))
pred_ergebniss=sum(pred_gesucht<325)+1
#217 Werte sind kleiner als 325 wir sehen uns also den 218 Datensatz an
seq[pred_ergebniss]
#Die deformation ist gr��er als 325 ab einem Durchsatz von 5947.317dm^3/h

#            b) Wir betreiben die Anlage mit einem Durchsatz der 15% unter dem Durchsatz
#               aus Punkt 6a liegt. Wenn nun unsere Teile nicht alle dieselbe Masse haben,
#               sondern die Masse normalverteilt mit Mittelwert gleich durchschnittlicher
#               Masse und Standardabweichung gleich 5% der durchschnittlichen Masse ist:
#               wie h�ufig (in Prozent) wird dann die Deformation gr��er 325 sein?
#               Was hie�e das f�r den Betrieb, wenn wir ab einer Deformation von 325 das
#               Sieb tauschen w�rden?

durchsatz85=5947.317*0.85
masse_mean=mean(dfn$masse)
masse_sd=masse_mean*0.05

set.seed(123)
masse_r=rnorm(1000, mean=masse_mean, sd=masse_sd)

pred_neu=predict(model2, data.frame(material="holz",
                                        geschw=mean(dfn$geschw),
                                        masse=masse_r,
                                        durchsatz=durchsatz85))
pred_neu_ergebniss=sum(pred_neu>325)
pred_neu_ergebniss
154/1000*100
#Die Deformation wird 15.4% h�her als 325 sein.
#Das hei�t in 15 von 100 F�llen tauschen wir das Sieb.