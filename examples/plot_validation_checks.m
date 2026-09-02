function figure_handle = plot_validation_checks(report)
%PLOT_VALIDATION_CHECKS Plot pass/fail status for physical validation checks.

arguments
    report (1,1) struct
end

if ~isfield(report, "checks") || isempty(report.checks)
    error("examples:ValidationChecksUnavailable", ...
        "The supplied report does not contain validation checks.");
end

checks = report.checks;
names = string({checks.name});
passed = double([checks.pass]);

figure_handle = figure("Name", "Simulation validation");
bar(categorical(names, names), passed);
ylim([-0.05, 1.05]);
yticks([0, 1]);
yticklabels(["fail", "pass"]);
ylabel("Validation status");
title(resolveTitle(report));
grid on
xtickangle(35);

end

function value = resolveTitle(report)
value = "Physical simulation validation";
if isfield(report, "summary") && strlength(string(report.summary)) > 0
    value = "Physical simulation validation: " + string(report.summary);
end
end
