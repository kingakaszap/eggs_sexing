
# Adapted from Timema_cov_tidier.py (D. J. Parker, Timema_facultative_partheno/accessory_scripts)
# for SINGLE-END data where ONE file = ONE sample (no paired/single/unpaired logic, no lane summing).
import sys, os, getopt

opts, args = getopt.getopt(sys.argv[1:], 'i:o:f:m:e:')
in_dir, fasta, out_base, min_len, ext = None, None, "COV_OUT", 0, "_contig_cov.txt"
for o, a in opts:
    if o == '-i': in_dir = a
    elif o == '-f': fasta = a
    elif o == '-o': out_base = a
    elif o == '-m': min_len = int(a)
    elif o == '-e': ext = a

# scaffold lengths from the fasta; name = first word of the header (the name used in the BAM header)
seq_len = {}
name = None
for line in open(fasta):
    line = line.rstrip("\n")
    if line.startswith(">"):
        name = line[1:].split()[0]
        seq_len[name] = 0
    else:
        seq_len[name] += len(line)

cov = {}
samples, contigs = [], set()
for fname in sorted(os.listdir(in_dir)):
    if not fname.endswith(ext):
        continue
    sample = fname[:-len(ext)]
    samples.append(sample)
    with open(os.path.join(in_dir, fname)) as fh:
        next(fh)  # header
        for line in fh:
            c, v = line.rstrip("\n").split(",")
            cov[(c, sample)] = v
            contigs.add(c)

print("Samples found:", len(samples))
out = open(out_base + "_minlen=" + str(min_len) + "_contig_cov.txt", "w")
out.write("contig,length," + ",".join(samples) + "\n")
n = 0
for c in sorted(contigs):
    L = seq_len.get(c)
    if L is None:
        print("WARNING: contig not in fasta:", c); continue
    if L >= min_len:
        out.write(c + "," + str(L) + "," + ",".join(cov.get((c, s), "NA") for s in samples) + "\n")
        n += 1
out.close()
print("Contigs written:", n)