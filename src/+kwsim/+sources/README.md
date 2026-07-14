# Reusable source configuration

The source API separates two independent decisions:

1. Field layout and regime.
2. Spatial contact model.

## Directional point-contact bank

~~~matlab
cfg = kwsim.two_d.defaultConfig();

cfg = kwsim.sources.configureVibratorBank( ...
    cfg, "directional", 12);

cfg = kwsim.sources.configurePointContact(cfg);
~~~

## Partially diffuse finite-contact bank

~~~matlab
cfg = kwsim.two_d.defaultConfig();

cfg = kwsim.sources.configureVibratorBank( ...
    cfg, ...
    "partially_diffuse", ...
    16, ...
    CoherentPowerFraction=0.5, ...
    TargetAngleDeg=20);

cfg = kwsim.sources.configureFiniteContact( ...
    cfg, ...
    ContactRadiusM=2e-3, ...
    NodeSpacingPoints=4, ...
    Profile="raised_cosine");
~~~

## Single point contact

~~~matlab
cfg = kwsim.two_d.defaultConfig();

cfg = kwsim.sources.configureSingleContact( ...
    cfg, ...
    VelocityAmplitudeMPerS=1e-6);

cfg = kwsim.sources.configurePointContact(cfg);
~~~

The configured structure is passed through the normal solver API:

~~~matlab
[result, report] = kwsim.two_d.run(cfg);
~~~
