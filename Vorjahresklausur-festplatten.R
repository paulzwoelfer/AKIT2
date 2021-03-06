# AKIT2, Klausur, 13.9.2017

library(car)
library(psych)
library(ROCR)
library(VIM)
library(ggplot2)
library(corrplot)
library(effects)
library(pwr)
library(runjags)
library(coda)
rjags::load.module("glm")
library(akit2)

# Die Betreiberin eines Rechenzentrums �berlegt ihre Festplattenkapazit�t aufzur�sten.
# Eine kosteneffiziente L�sung ist gefragt, weshalb Daten der letzten Jahre
# herangezogen werden, um auszuwerten, welche Festplatten zuk�nftig angeschafft
# werden sollen.
# 
# Der Datensatz enth�lt:
#   
# - marke ... Name des Herstellers
# - groesze ... Gr��e der Festplatte in TB
# - bauart ... 2.5" oder 3.5"
# - drehzahl ... Umdrehungsgeschwindigkeit in RPM
# - lautstaerke ... zuletzt gemessene Lautst�rke (in dB) der Festplatte im Betrieb
# - leistung ... Leistungsaufnahme in W
# - fehler ... 0 = kein Fehler, 1 = Festplatte ist im Beobachtungszeitraum ausgefallen


df = read.csv(file="C:\\Users\\Dominik\\Downloads\\festplatten.csv")

summary(df)
view(df)

hist(df$groesze)
hist(df$drehzahl)
hist(df$lautstaerke)
hist(df$leistung)
hist(df$fehler)
table(df$bauart)
df$bauart[df$bauart=="2.5in"]

# Fragestellung

# - Erstellen Sie Vorhersagemodelle getrennt f�r 2.5" und 3.5"-Festplatten,
#   ob eine Festplatte ausf�llt (Fehler=1) oder nicht.
#   Verifizieren Sie die beiden Modelle auf G�ltigkeit.
df25 = df[df$bauart=="2.5in",]
model1=glm(fehler ~ marke + groesze + drehzahl + lautstaerke + leistung, data = df25, family = binomial(link = "logit"))
df35 = df[df$bauart=="3.5in",]
model2=glm(fehler ~ marke + groesze + drehzahl + lautstaerke + leistung, data = df35, family = binomial(link = "logit"))

summary(model1)
summary(model2)

#----------------------------------Overdisperion

deviance(model1)/model1$df.residual
#Wert liegt leicht �ber 1. Noch ok.
deviance(model2)/model2$df.residual
#Wert liegt leicht �ber 1. Noch ok.

#------------------------------------Logit Test

hinkley(model1)
hinkley(model2)
#Sieh gut aus: keine Overdispersion, und der Hinkley-Test bestaetigt uns, dass Logit 
#passend ist und wohl keine unbekannte Variable das Ergebnis (stark) beeinflusst.

#--------------------------------Lineare Abh�ngigkeit

log.linearity.test(model1)
log.linearity.test(model2)
#Sieht alles ok aus.

vif(model1)
#Alle Werte sind unter 2 au�er drehzahl mit 2.3. Alles gut.
vif(model2)
#Alle unter 2. Gut.

#-----------------------------------Einflussreiche Werte / Ausrei�er

outlierTest(model1)
plot(model1, which=4)
plot(model1, which=5)
#Alle Werte sehen gut aus weshalb wir hier mit unserem Model weiter machen k�nnen.
outlierTest(model2)
plot(model2, which=4)
plot(model2, which=5)
#Schaut auch gut aus.

#--------------------------------------ROC Kurve

ROC(model1)
ROC(model2)
#Je gr��er die Fl�che unter der Kurve, desto besser ist das Modell. Perfekt w�re wenn die 
#Linie den gesamten Bereich 0.0 und 1.0 einschlie�en. ROC Kurve gibt Einblick wie gut das 
#Modell die Werte vom Datenset vorhersagt.
#Generell sehen beide Kurven nicht gerade super aus.

#--------------------------------------Variablentest
Anova(model1)
#marke und drehzahl hat den gr��ten Einfluss auf unser model1
Anova(model2)
#marke und drehzahl hat den gr��ten Einfluss auf unser model2

drop1(model1)[order(drop1(model1)[,3]),]
drop1(model2)[order(drop1(model2)[,3]),]
#In model2 verschlechtern die Variablen groesze und lautstaerke sogar das Modell.
#Ansonsten gleiches Ergebniss wie bei Anova.

############################################################################################
# - Interpetieren Sie die beiden Modelle, insbesondere die Koeffizienten.
#   Zeigen Sie konkrete Werte auch anhand selbst gew�hlter Beispieldaten.

summary(model1)
coef(model1)
coef(model2)
#markeSeagate und lautstaerke �ndert sich das Vorzeichen.

logisticR2(model1)
logisticR2(model2)
#Model2 sagt etwas Besser vorher aber es sind bei beiden Modellen niedrige Werte.

#----------------------------Interpretation:

intcp = inv.logit(coef(model1)[1]) #--> diese liefert direkt die absolute Wahrscheinlichkeit
#Ergebniss: 0.018 = 2% Wahrscheinlichkeit
#Basisfall Beispiel: Eine 2.5in der Marke HGST wo alle anderen metrischen Variablen 0 sind
#(was unsinnig ist) hat eine 2% Wahrscheinlichkeit einen Fehler zu haben.

intcp = inv.logit(coef(model2)[1]) #--> diese liefert direkt die absolute Wahrscheinlichkeit
#Ergebniss: 0.05 = 5% Wahrscheinlichkeit
#Basisfall Beispiel: Eine 3.5in der Marke HGST wo alle anderen metrischen Variablen 0 sind
#(was unsinnig ist) hat eine 5% Wahrscheinlichkeit einen Fehler zu haben.

#Ganzes Modell zur�ckrechnen:
exp(coef(model1))
#Wenn man die marke Western Digital anstatt HSTG nimmt erh�ht sich die Chance auf das 2.9-fache 
  #einen Fehler zu haben.
#Wenn man die marke Seagate nimmt senkt sich die Chance auf das 0.97-fache einen Fehler zu haben.
#Wenn die drehzahl um 1RPM steigt dann erh�gt sich die Chance auf das 1.00015-fache einen Fehler zu haben.
(exp(coef(model1)[6])^1000)
#Wenn die drehzahl um 1000RPM steigt dann erh�gt sich die Chance auf das 1.16-fache einen Fehler zu haben.

exp(coef(model2))
#Wenn man die marke Western Digital anstatt HSTG nimmt erh�ht sich die Chance auf das 4.3-fache 
  #einen Fehler zu haben.
#Wenn man die marke Toshiba nimmt senkt sich die Chance auf das 3.5-fache einen Fehler zu haben.
#Wenn die drehzahl um 1RPM steigt dann erh�gt sich die Chance auf das 1.00018-fache einen Fehler zu haben.
(exp(coef(model2)[6])^1000)
#Wenn die drehzahl um 1000RPM steigt dann erh�gt sich die Chance auf das 1.19-fache einen Fehler zu haben.

predict(model1, newdata = data.frame(
  marke=c("Seagate", "Toshiba", "Western Digital", "HGST"), 
  groesze=8, 
  drehzahl=4200, 
  lautstaerke=mean(df25$lautstaerke), 
  leistung=mean(df25$leistung)),
type='response')
#"Seagate",  "Toshiba",   "Western Digital",  "HGST"
#0.1760580,  0.2937397,   0.3903119,          0.1807298
#Seagate hat die geringste Wahrscheinlichkeit einen Fehler zu haben in Model1.

predict(model2, newdata = data.frame(
  marke=c("Seagate", "Toshiba", "Western Digital", "HGST"), 
  groesze=10, 
  drehzahl=7278, 
  lautstaerke=mean(df35$lautstaerke), 
  leistung=mean(df35$leistung)),
type='response')
#"Seagate",  "Toshiba",   "Western Digital",  "HGST"
#0.2791701,  0.5728412,   0.6225752,          0.2769739
#HGST hat die geringste Wahrscheinlichkeit einen Fehler zu haben in Model2.

#Drehzahl k�nnten wir noch probieren mit einmal min, mean und max um den Unterschied zu sehen.

############################################################################################
# - Beurteilen Sie die Vorhersagekraft beider Modelle im Vergleich.
#   Geben Sie weiters die Eigenschaften des 3.5"-Modells an, wenn es eine
#   True-Positive-Rate von 0.8 hat. Welche Schlussfolgerungen ziehen Sie daraus?
#Modellvergleiche wurden schon zuvor gemacht!

#---------------------------------Cutoff bestimmen
ROC(model1)
cutoff = 0.26
#Wenn wir cutoff~0.26 setzen, ergibt sich ein TPR von 0.8 (80% aller Fehler werden richtig 
#vorhergesagt) aber dabei ist dann FPR~0.55 (55% aller fehlerfreien Festplatten werden als 
#fehlerhaft vorhergesagt). Das ist viel und f�r die Praxis wohl kein guter Cutoff-Point.


############################################################################################
# - Neuanschaffung: wir wollen 500 2.5"-Festplatten anschaffen.
#   Welches Festplattenmodell soll gew�hlt werden?
#   Welches ist in Summe[^1] am g�nstigsten[^2]?
#   Folgende Modelle stehen zur Auswahl:
#     - HGST, 6TB, 5940rpm, 6.5W, 22dB, Preis: Euro254,-
#     - Seagate, 6TB, 7200rpm, 7W, 26dB, Preis: Euro230,-
#     - Toshiba, 6TB, 10000rpm, 10.5W, 32dB, Preis: Euro158,-
#     - Western Digital, 6TB, 10000rpm, 10W, 30dB, Preis: Euro180,-
p1_25 = predict(model1, newdata = data.frame(
  marke="HGST", groesze=6, drehzahl=5940, lautstaerke=22, leistung=6.5), type='response')
p2_25 = predict(model1, newdata = data.frame(
  marke="Seagate", groesze=6, drehzahl=7200, lautstaerke=26, leistung=7), type='response')
p3_25 = predict(model1, newdata = data.frame(
  marke="Toshiba", groesze=6, drehzahl=10000, lautstaerke=32, leistung=10.5), type='response')
p4_25 = predict(model1, newdata = data.frame(
  marke="Western Digital", groesze=6, drehzahl=10000, lautstaerke=30, leistung=10), type='response')
c(p1_25, p2_25, p3_25, p4_25)
500*(1+p1_25)*254 #152596.6
500*(1+p2_25)*230 #145337.9 
500*(1+p3_25)*158 #130687.7
500*(1+p4_25)*180 #154776.2

#Wir k�nnen sehen das die Toshiba am g�nstigsten sein w�rde.


# [^1]: Ohne Ber�cksichtigung von Strom- und Personalkosten; gehen Sie davon aus,
#       dass fehlerhafte Festplatten nur ein einziges Mal nachgekauft werden müssen.
# [^2]: Sie sollten nicht nur Punktwerte berechnen, sondern (so weit m�glich)
#       gleich Konfidenzintervalle.